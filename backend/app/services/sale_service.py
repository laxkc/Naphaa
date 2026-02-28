from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.calendar import business_date_from_timestamp
from app.models.store import Store
from app.models.customer import Customer
from app.models.sale_payment import SalePayment
from app.models.sale import Sale, SaleItem
from app.models.sale_refund import SaleRefund, SaleRefundItem
from app.models.product import Product
from app.schemas.sale import SaleCreate, SaleRefundCreate, SaleType
from app.core.errors import raise_api_error
from app.models.stock_movement import StockMovement
from app.services.inventory_service import InventoryService
from app.services.ledger_service import LedgerService
from app.services.sync_event_service import SyncEventService


class SaleService:
    @staticmethod
    def create_sale(
        db: Session,
        store_id: str,
        payload: SaleCreate,
        actor_user_id: str,
        idempotency_key: str | None = None,
        device_id: str | None = None,
    ) -> Sale:
        store = db.scalar(select(Store).where(Store.id == store_id))
        if idempotency_key:
            existing_sale = db.scalar(
                select(Sale).where(
                    Sale.store_id == store_id,
                    Sale.idempotency_key == idempotency_key,
                )
            )
            if existing_sale is not None:
                hydrated = db.scalar(
                    select(Sale)
                    .where(Sale.id == existing_sale.id)
                    .options(selectinload(Sale.items))
                )
                assert hydrated is not None
                return hydrated

        total_from_items = sum((item.qty * item.unit_price for item in payload.items), Decimal("0"))
        payments_payload = payload.payments or []
        payment_method = str(getattr(payload.payment_method, "value", payload.payment_method or "")).upper()
        if payments_payload:
            payment_total = sum((Decimal(p.amount) for p in payments_payload), Decimal("0"))
            if payment_total != total_from_items:
                raise_api_error(
                    status.HTTP_400_BAD_REQUEST,
                    "PAYMENT_TOTAL_MISMATCH",
                    "Sum of payment amounts must match sale total",
                )
            credit_component = sum(
                (
                    Decimal(p.amount)
                    for p in payments_payload
                    if str(getattr(p.method, "value", p.method)).upper() == "CREDIT"
                ),
                Decimal("0"),
            )
        else:
            if payload.sale_type == SaleType.MIXED:
                raise_api_error(
                    status.HTTP_400_BAD_REQUEST,
                    "PAYMENTS_REQUIRED_FOR_MIXED_SALE",
                    "payments are required for MIXED sale",
                )
            if not payment_method:
                payment_method = "CREDIT" if payload.sale_type == SaleType.CREDIT else "CASH"
            if payload.sale_type == SaleType.CREDIT and payment_method != "CREDIT":
                raise_api_error(
                    status.HTTP_400_BAD_REQUEST,
                    "INVALID_PAYMENT_METHOD_FOR_CREDIT_SALE",
                    "payment_method must be CREDIT for CREDIT sale",
                )
            if payload.sale_type == SaleType.CASH and payment_method == "CREDIT":
                raise_api_error(
                    status.HTTP_400_BAD_REQUEST,
                    "INVALID_PAYMENT_METHOD_FOR_CASH_SALE",
                    "CASH sale cannot use CREDIT payment method without split payments",
                )
            credit_component = total_from_items if payload.sale_type == SaleType.CREDIT else Decimal("0")

        if payments_payload:
            if credit_component == total_from_items:
                resolved_sale_type = SaleType.CREDIT.value
                resolved_payment_method = "CREDIT"
            elif credit_component == 0:
                resolved_sale_type = SaleType.CASH.value
                non_credit = [str(getattr(p.method, "value", p.method)).upper() for p in payments_payload if str(getattr(p.method, "value", p.method)).upper() != "CREDIT"]
                resolved_payment_method = non_credit[0] if non_credit else "CASH"
            else:
                resolved_sale_type = SaleType.MIXED.value
                resolved_payment_method = "MIXED"
        else:
            resolved_sale_type = payload.sale_type.value
            resolved_payment_method = payment_method

        if credit_component > 0 and not payload.customer_id:
            raise_api_error(
                status.HTTP_400_BAD_REQUEST,
                "CUSTOMER_REQUIRED_FOR_CREDIT_SALE",
                "customer_id is required for credit sale",
            )

        customer = None
        if payload.customer_id:
            customer = db.scalar(
                select(Customer).where(
                    Customer.id == payload.customer_id,
                    Customer.store_id == store_id,
                )
            )
            if customer is None:
                raise_api_error(status.HTTP_404_NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")

        try:
            sale = Sale(
                store_id=store_id,
                sale_type=resolved_sale_type,
                payment_method=resolved_payment_method,
                customer_id=payload.customer_id,
                total_amount=Decimal("0"),
                sale_date_ad=business_date_from_timestamp(
                    value=None,
                    timezone_name=store.business_timezone if store else None,
                ),
                idempotency_key=idempotency_key,
                created_by=actor_user_id,
                updated_by=actor_user_id,
                device_id=device_id,
            )
            db.add(sale)
            db.flush()

            total = Decimal("0")
            for item in payload.items:
                product = InventoryService.get_product_for_store(db, store_id, item.product_id)
                InventoryService.deduct_stock(db, product, item.qty)
                db.add(
                    StockMovement(
                        store_id=store_id,
                        product_id=product.id,
                        movement_type="SALE_DEDUCTION",
                        delta_qty=Decimal(item.qty) * Decimal("-1"),
                        balance_after=Decimal(product.stock_qty),
                        reference_type="SALE",
                        reference_id=sale.id,
                        created_by=actor_user_id,
                        device_id=device_id,
                    )
                )

                line_total = item.qty * item.unit_price
                total += line_total

                db.add(
                    SaleItem(
                        sale_id=sale.id,
                        product_id=item.product_id,
                        qty=item.qty,
                        unit_price=item.unit_price,
                        line_total=line_total,
                    )
                )

            sale.total_amount = total
            if not payments_payload:
                db.add(
                    SalePayment(
                        sale_id=sale.id,
                        method=resolved_payment_method,
                        amount=total,
                    )
                )
            else:
                for payment in payments_payload:
                    db.add(
                        SalePayment(
                            sale_id=sale.id,
                            method=str(getattr(payment.method, "value", payment.method)).upper(),
                            amount=Decimal(payment.amount),
                        )
                    )

            if credit_component > 0 and customer is not None:
                customer.balance = Decimal(customer.balance) + credit_component
                customer.updated_by = actor_user_id
                customer.device_id = device_id
                db.add(customer)

            db.add(sale)
            db.flush()
            LedgerService.record_sale(db, sale, credit_component=credit_component)
            hydrated_for_sync = db.scalar(
                select(Sale)
                .where(Sale.id == sale.id)
                .options(selectinload(Sale.items), selectinload(Sale.payments))
            )
            if hydrated_for_sync is not None:
                SyncEventService.emit(
                    db,
                    store_id=store_id,
                    entity="sale",
                    operation="UPSERT",
                    payload=SyncEventService.sale_payload(hydrated_for_sync),
                )
            if customer is not None:
                SyncEventService.emit(
                    db,
                    store_id=store_id,
                    entity="customer",
                    operation="UPSERT",
                    payload=SyncEventService.customer_payload(customer),
                )
            db.commit()
        except HTTPException:
            db.rollback()
            raise
        except Exception:
            db.rollback()
            raise

        created_sale = db.scalar(
            select(Sale)
            .where(Sale.id == sale.id)
            .options(selectinload(Sale.items), selectinload(Sale.payments))
        )
        assert created_sale is not None
        return created_sale

    @staticmethod
    def refund_sale(
        db: Session,
        store_id: str,
        sale_id: str,
        payload: SaleRefundCreate,
        actor_user_id: str,
        device_id: str | None = None,
    ) -> SaleRefund:
        store = db.scalar(select(Store).where(Store.id == store_id))
        sale = db.scalar(
            select(Sale)
            .where(Sale.id == sale_id, Sale.store_id == store_id)
            .options(selectinload(Sale.items), selectinload(Sale.payments))
        )
        if sale is None:
            raise_api_error(status.HTTP_404_NOT_FOUND, "SALE_NOT_FOUND", "Sale not found")

        sold_map: dict[str, tuple[Decimal, Decimal]] = {}
        for item in sale.items:
            sold_map[item.product_id] = (Decimal(item.qty), Decimal(item.unit_price))

        refunded_rows = db.execute(
            select(
                SaleRefundItem.product_id,
                func.coalesce(func.sum(SaleRefundItem.qty), 0),
            )
            .join(SaleRefund, SaleRefund.id == SaleRefundItem.refund_id)
            .where(
                SaleRefund.store_id == store_id,
                SaleRefund.sale_id == sale_id,
            )
            .group_by(SaleRefundItem.product_id)
        ).all()
        refunded_map = {product_id: Decimal(total_qty) for product_id, total_qty in refunded_rows}

        sale_item_to_product = {item.id: item.product_id for item in sale.items}

        if payload.items:
            requested: list[tuple[str, Decimal]] = []
            for item in payload.items:
                product_id = item.product_id
                if product_id is None and item.sale_item_id is not None:
                    product_id = sale_item_to_product.get(item.sale_item_id)
                    if product_id is None:
                        raise_api_error(
                            status.HTTP_400_BAD_REQUEST,
                            "REFUND_ITEM_NOT_IN_SALE",
                            "Refund item is not part of this sale",
                        )
                if product_id is None:
                    raise_api_error(
                        status.HTTP_400_BAD_REQUEST,
                        "REFUND_ITEM_REFERENCE_REQUIRED",
                        "Either product_id or sale_item_id is required",
                    )
                requested.append((product_id, Decimal(item.qty)))
        else:
            requested = []
            for product_id, (sold_qty, _) in sold_map.items():
                remaining = sold_qty - refunded_map.get(product_id, Decimal("0"))
                if remaining > 0:
                    requested.append((product_id, remaining))

        if not requested:
            raise_api_error(status.HTTP_400_BAD_REQUEST, "NOTHING_TO_REFUND", "No refundable items found")

        refund_lines: list[tuple[str, Decimal, Decimal, Decimal]] = []
        refund_total = Decimal("0")
        for product_id, qty in requested:
            if product_id not in sold_map:
                raise_api_error(
                    status.HTTP_400_BAD_REQUEST,
                    "REFUND_ITEM_NOT_IN_SALE",
                    "Refund item is not part of this sale",
                )
            sold_qty, unit_price = sold_map[product_id]
            already_refunded = refunded_map.get(product_id, Decimal("0"))
            remaining = sold_qty - already_refunded
            if qty <= 0:
                raise_api_error(status.HTTP_400_BAD_REQUEST, "INVALID_REFUND_QTY", "Refund quantity must be greater than zero")
            if qty > remaining:
                raise_api_error(
                    status.HTTP_400_BAD_REQUEST,
                    "REFUND_EXCEEDS_SOLD_QTY",
                    "Refund quantity exceeds remaining sold quantity",
                )
            line_total = qty * unit_price
            refund_lines.append((product_id, qty, unit_price, line_total))
            refund_total += line_total

        if refund_total <= 0:
            raise_api_error(status.HTTP_400_BAD_REQUEST, "INVALID_REFUND_AMOUNT", "Refund amount must be greater than zero")

        previous_refunds_total = Decimal(
            db.scalar(
                select(func.coalesce(func.sum(SaleRefund.amount), 0)).where(
                    SaleRefund.store_id == store_id,
                    SaleRefund.sale_id == sale_id,
                )
            )
            or 0
        )
        original_credit_component = sum(
            (
                Decimal(p.amount)
                for p in sale.payments
                if str(p.method).upper() == "CREDIT"
            ),
            Decimal("0"),
        )
        if not sale.payments and sale.sale_type == SaleType.CREDIT.value:
            original_credit_component = Decimal(sale.total_amount) + previous_refunds_total

        credit_refunded_to_date = min(original_credit_component, previous_refunds_total)
        credit_refundable_remaining = max(
            Decimal("0"),
            original_credit_component - credit_refunded_to_date,
        )
        credit_refund_for_this_request = min(credit_refundable_remaining, refund_total)

        try:
            refund = SaleRefund(
                store_id=store_id,
                sale_id=sale_id,
                amount=refund_total,
                refund_date_ad=business_date_from_timestamp(
                    value=None,
                    timezone_name=store.business_timezone if store else None,
                ),
                reason=(payload.reason or "").strip() or None,
                created_by=actor_user_id,
                device_id=device_id,
            )
            db.add(refund)
            db.flush()

            for product_id, qty, unit_price, line_total in refund_lines:
                product = db.scalar(
                    select(Product).where(
                        Product.id == product_id,
                        Product.store_id == store_id,
                    )
                )
                if product is None:
                    raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")

                product.stock_qty = Decimal(product.stock_qty) + qty
                product.updated_by = actor_user_id
                product.device_id = device_id
                db.add(
                    StockMovement(
                        store_id=store_id,
                        product_id=product.id,
                        movement_type="REFUND_RESTOCK",
                        delta_qty=qty,
                        balance_after=Decimal(product.stock_qty),
                        reason=payload.reason,
                        reference_type="SALE_REFUND",
                        reference_id=refund.id,
                        created_by=actor_user_id,
                        device_id=device_id,
                    )
                )
                db.add(product)

                db.add(
                    SaleRefundItem(
                        refund_id=refund.id,
                        sale_id=sale_id,
                        product_id=product_id,
                        qty=qty,
                        unit_price=unit_price,
                        line_total=line_total,
                    )
                )

            sale.total_amount = max(Decimal("0"), Decimal(sale.total_amount) - refund_total)
            sale.updated_by = actor_user_id
            sale.device_id = device_id
            db.add(sale)

            if credit_refund_for_this_request > 0 and sale.customer_id:
                customer = db.scalar(
                    select(Customer).where(
                        Customer.id == sale.customer_id,
                        Customer.store_id == store_id,
                    )
                )
                if customer is not None:
                    customer.balance = max(
                        Decimal("0"),
                        Decimal(customer.balance) - credit_refund_for_this_request,
                    )
                    customer.updated_by = actor_user_id
                    customer.device_id = device_id
                    db.add(customer)

            LedgerService.record_refund(
                db,
                refund,
                customer_id=sale.customer_id,
                sale_id=sale.id,
            )

            db.commit()
        except HTTPException:
            db.rollback()
            raise
        except Exception:
            db.rollback()
            raise

        created_refund = db.scalar(
            select(SaleRefund)
            .where(SaleRefund.id == refund.id)
            .options(selectinload(SaleRefund.items))
        )
        assert created_refund is not None
        return created_refund
