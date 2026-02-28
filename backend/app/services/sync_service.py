from datetime import UTC, date, datetime
from decimal import Decimal, InvalidOperation
import hashlib
import json
import logging
from time import perf_counter

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.core.calendar import business_date_from_timestamp
from app.models.customer import Customer
from app.models.customer_payment import CustomerPayment
from app.models.expense import Expense
from app.models.product import Product
from app.models.sale import Sale, SaleItem
from app.models.sale_payment import SalePayment
from app.models.sync_event import SyncEvent
from app.services.inventory_service import InventoryService
from app.services.ledger_service import LedgerService
from app.schemas.sync import (
    SyncPushFailedEvent,
    SyncPullEvent,
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResponse,
    SyncStatusResponse,
)


class SyncApplyError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


class SyncService:
    _log = logging.getLogger("app.sync")

    @staticmethod
    def _to_decimal(value: object, *, default: str = "0") -> Decimal:
        if value is None:
            return Decimal(default)
        try:
            return Decimal(str(value))
        except (InvalidOperation, ValueError):
            return Decimal(default)

    @staticmethod
    def _to_datetime(value: object) -> datetime | None:
        if isinstance(value, datetime):
            if value.tzinfo is None:
                return None
            return value.astimezone(UTC)
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return None
            if not raw.endswith("Z"):
                return None
            try:
                parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
                if parsed.tzinfo is None:
                    return None
                return parsed.astimezone(UTC)
            except ValueError:
                return None
        return None

    @staticmethod
    def _ensure_immutable_business_date(
        *,
        entity_name: str,
        existing_date: date | None,
        incoming_date: date | None,
    ) -> None:
        if incoming_date is None or existing_date is None:
            return
        if incoming_date != existing_date:
            raise SyncApplyError(
                "IMMUTABLE_BUSINESS_DATE",
                f"{entity_name} business date cannot be changed after creation",
            )

    @staticmethod
    def _to_date(value: object) -> date | None:
        if isinstance(value, date) and not isinstance(value, datetime):
            return value
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return None
            try:
                return date.fromisoformat(raw)
            except ValueError:
                return None
        return None

    @staticmethod
    def _apply_product_event(db: Session, store_id: str, operation: str, payload: dict) -> None:
        op = operation.upper()
        product_id = str(payload.get("id") or "").strip()
        if product_id == "":
            raise SyncApplyError("INVALID_PAYLOAD", "product.id is required")

        product = db.scalar(
            select(Product).where(
                Product.id == product_id,
                Product.store_id == store_id,
            )
        )

        if op == "DELETE":
            if product is None:
                raise SyncApplyError("PRODUCT_NOT_FOUND", "Product not found for delete")
            product.is_deleted = True
            product.is_active = False
            if product.deleted_at is None:
                product.deleted_at = datetime.now(UTC)
            if payload.get("device_id"):
                product.device_id = str(payload.get("device_id"))
            db.add(product)
            return

        if op == "ADJUST_STOCK":
            if product is None:
                raise SyncApplyError("PRODUCT_NOT_FOUND", "Product not found for stock adjustment")
            delta = SyncService._to_decimal(payload.get("delta_qty"))
            try:
                InventoryService.adjust_stock(db, product, delta)
            except Exception as exc:
                if getattr(exc, "status_code", None) == 400:
                    raise SyncApplyError("INSUFFICIENT_STOCK", "Stock adjustment would make stock negative") from exc
                raise
            product.device_id = str(payload.get("device_id")) if payload.get("device_id") else product.device_id
            db.add(product)
            return

        if op != "UPSERT":
            raise SyncApplyError("UNSUPPORTED_OPERATION", f"Unsupported product operation: {op}")

        if product is None:
            name = str(payload.get("name") or "").strip()
            if name == "":
                raise SyncApplyError("INVALID_PAYLOAD", "product.name is required for create")
            product = Product(
                id=product_id,
                store_id=store_id,
                name=name,
                sell_price=SyncService._to_decimal(payload.get("sell_price")),
                cost_price=SyncService._to_decimal(payload.get("cost_price")),
                stock_qty=SyncService._to_decimal(payload.get("stock_qty")),
                low_stock_threshold=SyncService._to_decimal(payload.get("low_stock_threshold")),
                is_active=bool(payload.get("is_active", True)),
                created_by=None,
                updated_by=None,
                device_id=str(payload.get("device_id")) if payload.get("device_id") else None,
            )
            db.add(product)
            return

        if "name" in payload and str(payload.get("name") or "").strip() != "":
            product.name = str(payload["name"]).strip()
        payload_updated_at = SyncService._to_datetime(payload.get("updated_at"))
        if payload_updated_at is not None and product.updated_at is not None:
            server_updated_at = product.updated_at
            if (
                server_updated_at.tzinfo is not None
                and payload_updated_at.tzinfo is None
            ):
                payload_updated_at = payload_updated_at.replace(tzinfo=UTC)
            elif (
                server_updated_at.tzinfo is None
                and payload_updated_at.tzinfo is not None
            ):
                server_updated_at = server_updated_at.replace(tzinfo=UTC)
            if payload_updated_at < server_updated_at:
                raise SyncApplyError("CONFLICT_STALE_EVENT", "Stale product update rejected by server")
        if "sell_price" in payload:
            product.sell_price = SyncService._to_decimal(payload.get("sell_price"))
        if "cost_price" in payload:
            product.cost_price = SyncService._to_decimal(payload.get("cost_price"))
        if "stock_qty" in payload:
            product.stock_qty = SyncService._to_decimal(payload.get("stock_qty"))
        if "low_stock_threshold" in payload:
            product.low_stock_threshold = SyncService._to_decimal(payload.get("low_stock_threshold"))
        if "is_active" in payload:
            product.is_active = bool(payload.get("is_active"))
        if payload.get("device_id"):
            product.device_id = str(payload.get("device_id"))
        db.add(product)

    @staticmethod
    def _apply_customer_event(db: Session, store_id: str, operation: str, payload: dict) -> None:
        op = operation.upper()
        if op not in ("UPSERT", "DELETE"):
            raise SyncApplyError("UNSUPPORTED_OPERATION", f"Unsupported customer operation: {op}")
        customer_id = str(payload.get("id") or "").strip()
        if customer_id == "":
            raise SyncApplyError("INVALID_PAYLOAD", "customer.id is required")
        customer = db.scalar(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.store_id == store_id,
            )
        )
        if op == "DELETE":
            if customer is None:
                raise SyncApplyError("CUSTOMER_NOT_FOUND", "Customer not found for delete")
            customer.is_deleted = True
            if customer.deleted_at is None:
                customer.deleted_at = datetime.now(UTC)
            if payload.get("device_id"):
                customer.device_id = str(payload.get("device_id"))
            db.add(customer)
            return

        if customer is None:
            name = str(payload.get("name") or "").strip()
            if name == "":
                raise SyncApplyError("INVALID_PAYLOAD", "customer.name is required for create")
            customer = Customer(
                id=customer_id,
                store_id=store_id,
                name=name,
                phone=(str(payload.get("phone")).strip() if payload.get("phone") else None),
                balance=SyncService._to_decimal(payload.get("balance")),
                is_deleted=bool(payload.get("is_deleted", False)),
                device_id=str(payload.get("device_id")) if payload.get("device_id") else None,
                deleted_at=datetime.now(UTC) if bool(payload.get("is_deleted", False)) else None,
            )
            db.add(customer)
            return

        if "name" in payload and str(payload.get("name") or "").strip() != "":
            customer.name = str(payload["name"]).strip()
        payload_updated_at = SyncService._to_datetime(payload.get("updated_at"))
        if payload_updated_at is not None and customer.updated_at is not None:
            server_updated_at = customer.updated_at
            if (
                server_updated_at.tzinfo is not None
                and payload_updated_at.tzinfo is None
            ):
                payload_updated_at = payload_updated_at.replace(tzinfo=UTC)
            elif (
                server_updated_at.tzinfo is None
                and payload_updated_at.tzinfo is not None
            ):
                server_updated_at = server_updated_at.replace(tzinfo=UTC)
            if payload_updated_at < server_updated_at:
                raise SyncApplyError("CONFLICT_STALE_EVENT", "Stale customer update rejected by server")
        if "phone" in payload:
            customer.phone = str(payload["phone"]).strip() if payload.get("phone") else None
        if "balance" in payload:
            customer.balance = SyncService._to_decimal(payload.get("balance"))
        if "is_deleted" in payload:
            customer.is_deleted = bool(payload.get("is_deleted"))
            if customer.is_deleted and customer.deleted_at is None:
                customer.deleted_at = datetime.now(UTC)
        if payload.get("device_id"):
            customer.device_id = str(payload.get("device_id"))
        db.add(customer)

    @staticmethod
    def _apply_customer_payment_event(db: Session, store_id: str, operation: str, payload: dict) -> None:
        if operation.upper() != "UPSERT":
            raise SyncApplyError("UNSUPPORTED_OPERATION", f"Unsupported customer_payment operation: {operation.upper()}")
        payment_id = str(payload.get("id") or "").strip()
        customer_id = str(payload.get("customer_id") or "").strip()
        if payment_id == "" or customer_id == "":
            raise SyncApplyError("INVALID_PAYLOAD", "customer_payment.id and customer_id are required")

        existing = db.scalar(
            select(CustomerPayment).where(
                CustomerPayment.id == payment_id,
                CustomerPayment.store_id == store_id,
            )
        )
        incoming_payment_date = SyncService._to_date(payload.get("payment_date_ad")) or business_date_from_timestamp(
            value=SyncService._to_datetime(payload.get("created_at")),
            timezone_name=None,
        )
        if existing is not None:
            SyncService._ensure_immutable_business_date(
                entity_name="customer_payment",
                existing_date=existing.payment_date_ad,
                incoming_date=incoming_payment_date,
            )
            return

        customer = db.scalar(
            select(Customer).where(
                Customer.id == customer_id,
                Customer.store_id == store_id,
            )
        )
        if customer is None:
            raise SyncApplyError("CUSTOMER_NOT_FOUND", "Customer not found for payment")

        amount = SyncService._to_decimal(payload.get("amount"))
        if amount <= 0:
            raise SyncApplyError("INVALID_PAYLOAD", "customer_payment.amount must be greater than zero")

        payment = CustomerPayment(
            id=payment_id,
            store_id=store_id,
            customer_id=customer_id,
            method=str(payload.get("method") or "CASH").upper(),
            amount=amount,
            payment_date_ad=incoming_payment_date,
            note=payload.get("note"),
            device_id=str(payload.get("device_id")) if payload.get("device_id") else None,
            created_at=SyncService._to_datetime(payload.get("created_at")),
        )
        customer.balance = max(Decimal("0"), Decimal(customer.balance) - amount)
        if payload.get("device_id"):
            customer.device_id = str(payload.get("device_id"))
        db.add(payment)
        db.add(customer)
        LedgerService.record_customer_payment(db, payment)

    @staticmethod
    def _apply_expense_event(db: Session, store_id: str, operation: str, payload: dict) -> None:
        op = operation.upper()
        if op not in ("UPSERT", "DELETE"):
            raise SyncApplyError("UNSUPPORTED_OPERATION", f"Unsupported expense operation: {op}")
        expense_id = str(payload.get("id") or "").strip()
        if expense_id == "":
            raise SyncApplyError("INVALID_PAYLOAD", "expense.id is required")
        expense = db.scalar(
            select(Expense).where(
                Expense.id == expense_id,
                Expense.store_id == store_id,
            )
        )
        if op == "DELETE":
            if expense is None:
                raise SyncApplyError("EXPENSE_NOT_FOUND", "Expense not found for delete")
            if expense.deleted_at is None:
                expense.deleted_at = datetime.now(UTC)
            if payload.get("device_id"):
                expense.device_id = str(payload.get("device_id"))
            db.add(expense)
            return
        incoming_expense_date = SyncService._to_date(payload.get("expense_date_ad")) or business_date_from_timestamp(
            value=SyncService._to_datetime(payload.get("created_at")),
            timezone_name=None,
        )
        if expense is None:
            category = str(payload.get("category") or "").strip()
            if category == "":
                raise SyncApplyError("INVALID_PAYLOAD", "expense.category is required for create")
            expense = Expense(
                id=expense_id,
                store_id=store_id,
                category=category,
                amount=SyncService._to_decimal(payload.get("amount")),
                expense_date_ad=incoming_expense_date,
                note=payload.get("note"),
                device_id=str(payload.get("device_id")) if payload.get("device_id") else None,
                created_at=SyncService._to_datetime(payload.get("created_at")),
            )
            db.add(expense)
            LedgerService.record_expense(db, expense)
            return

        SyncService._ensure_immutable_business_date(
            entity_name="expense",
            existing_date=expense.expense_date_ad,
            incoming_date=incoming_expense_date,
        )

        if "category" in payload and str(payload.get("category") or "").strip() != "":
            expense.category = str(payload["category"]).strip()
        if "amount" in payload:
            expense.amount = SyncService._to_decimal(payload.get("amount"))
        if "note" in payload:
            expense.note = payload.get("note")
        if payload.get("device_id"):
            expense.device_id = str(payload.get("device_id"))
        db.add(expense)

    @staticmethod
    def _sale_credit_amount(payload: dict) -> Decimal:
        payments = payload.get("payments")
        if isinstance(payments, list) and len(payments) > 0:
            total = Decimal("0")
            for p in payments:
                if not isinstance(p, dict):
                    continue
                method = str(p.get("method") or "").upper()
                if method == "CREDIT":
                    total += SyncService._to_decimal(p.get("amount"))
            return total
        if str(payload.get("sale_type") or "").upper() == "CREDIT":
            return SyncService._to_decimal(payload.get("total_amount"))
        return Decimal("0")

    @staticmethod
    def _apply_sale_event(db: Session, store_id: str, operation: str, payload: dict) -> None:
        if operation.upper() != "UPSERT":
            raise SyncApplyError("UNSUPPORTED_OPERATION", f"Unsupported sale operation: {operation.upper()}")
        sale_id = str(payload.get("id") or "").strip()
        if sale_id == "":
            raise SyncApplyError("INVALID_PAYLOAD", "sale.id is required")
        existing_sale = db.scalar(
            select(Sale).where(
                Sale.id == sale_id,
                Sale.store_id == store_id,
            )
        )
        incoming_sale_date = SyncService._to_date(payload.get("sale_date_ad")) or business_date_from_timestamp(
            value=SyncService._to_datetime(payload.get("created_at")),
            timezone_name=None,
        )
        # Avoid double-deducting stock / customer balance on duplicate or replayed sale events.
        if existing_sale is not None:
            SyncService._ensure_immutable_business_date(
                entity_name="sale",
                existing_date=existing_sale.sale_date_ad,
                incoming_date=incoming_sale_date,
            )
            return

        items = payload.get("items") if isinstance(payload.get("items"), list) else []
        if len(items) == 0:
            raise SyncApplyError("INVALID_PAYLOAD", "sale.items is required")
        normalized_items: list[dict] = []
        computed_total = Decimal("0")
        for raw_item in items:
            if not isinstance(raw_item, dict):
                raise SyncApplyError("INVALID_PAYLOAD", "sale.items entries must be objects")
            product_id = str(raw_item.get("product_id") or "").strip()
            if product_id == "":
                raise SyncApplyError("INVALID_PAYLOAD", "sale_item.product_id is required")
            qty = SyncService._to_decimal(raw_item.get("qty"))
            unit_price = SyncService._to_decimal(raw_item.get("unit_price"))
            if qty <= 0:
                raise SyncApplyError("INVALID_PAYLOAD", "sale_item.qty must be greater than zero")
            if unit_price < 0:
                raise SyncApplyError("INVALID_PAYLOAD", "sale_item.unit_price cannot be negative")
            product = db.scalar(
                select(Product).where(
                    Product.id == product_id,
                    Product.store_id == store_id,
                )
            )
            if product is None:
                raise SyncApplyError("PRODUCT_NOT_FOUND", f"Product not found: {product_id}")
            if Decimal(product.stock_qty) < qty:
                raise SyncApplyError("INSUFFICIENT_STOCK", f"Insufficient stock for product {product_id}")
            line_total = qty * unit_price
            computed_total += line_total
            normalized_items.append(
                {
                    "product": product,
                    "product_id": product_id,
                    "qty": qty,
                    "unit_price": unit_price,
                    "line_total": line_total,
                }
            )

        payload_total = SyncService._to_decimal(payload.get("total_amount"))
        if payload_total != computed_total:
            raise SyncApplyError("PAYMENT_TOTAL_MISMATCH", "sale.total_amount does not match item totals")

        payments = payload.get("payments") if isinstance(payload.get("payments"), list) else []
        if len(payments) > 0:
            payment_total = Decimal("0")
            for raw_payment in payments:
                if not isinstance(raw_payment, dict):
                    raise SyncApplyError("INVALID_PAYLOAD", "sale.payments entries must be objects")
                amount = SyncService._to_decimal(raw_payment.get("amount"))
                if amount < 0:
                    raise SyncApplyError("INVALID_PAYLOAD", "sale_payment.amount cannot be negative")
                payment_total += amount
            if payment_total != payload_total:
                raise SyncApplyError("PAYMENT_TOTAL_MISMATCH", "sale payments total does not match sale total")

        credit_amount = SyncService._sale_credit_amount(payload)
        if credit_amount > 0 and not str(payload.get("customer_id") or "").strip():
            raise SyncApplyError("CUSTOMER_REQUIRED_FOR_CREDIT_SALE", "customer_id is required for credit sale")

        customer = None
        if str(payload.get("customer_id") or "").strip():
            customer = db.scalar(
                select(Customer).where(
                    Customer.id == str(payload.get("customer_id")).strip(),
                    Customer.store_id == store_id,
                )
            )
            if customer is None:
                raise SyncApplyError("CUSTOMER_NOT_FOUND", "Customer not found")

        sale = Sale(
            id=sale_id,
            store_id=store_id,
            sale_type=str(payload.get("sale_type") or "CASH").upper(),
            payment_method=str(payload.get("payment_method") or "CASH").upper(),
            customer_id=(str(payload.get("customer_id")).strip() if payload.get("customer_id") else None),
            total_amount=SyncService._to_decimal(payload.get("total_amount")),
            sale_date_ad=incoming_sale_date,
            device_id=str(payload.get("device_id")) if payload.get("device_id") else None,
            created_at=SyncService._to_datetime(payload.get("created_at")),
        )
        db.add(sale)
        db.flush()

        for item in normalized_items:
            product = item["product"]
            product_id = str(item["product_id"])
            qty = item["qty"]
            unit_price = item["unit_price"]
            line_total = item["line_total"]
            try:
                InventoryService.deduct_stock(db, product, qty)
            except Exception as exc:
                if getattr(exc, "status_code", None) == 400:
                    raise SyncApplyError("INSUFFICIENT_STOCK", f"Insufficient stock for product {product_id}") from exc
                raise
            if payload.get("device_id"):
                product.device_id = str(payload.get("device_id"))
            db.add(product)

            db.add(
                SaleItem(
                    sale_id=sale.id,
                    product_id=product_id,
                    qty=qty,
                    unit_price=unit_price,
                    line_total=line_total,
                )
            )

        if len(payments) == 0:
            db.add(
                SalePayment(
                    sale_id=sale.id,
                    method=str(payload.get("payment_method") or "CASH").upper(),
                    amount=payload_total,
                )
            )
        else:
            for raw_payment in payments:
                if not isinstance(raw_payment, dict):
                    continue
                payment_kwargs = {
                    "sale_id": sale.id,
                    "method": str(raw_payment.get("method") or "CASH").upper(),
                    "amount": SyncService._to_decimal(raw_payment.get("amount")),
                }
                if raw_payment.get("id"):
                    payment_kwargs["id"] = str(raw_payment.get("id"))
                db.add(
                    SalePayment(
                        **payment_kwargs,
                    )
                )

        if credit_amount > 0 and sale.customer_id:
            if customer is not None:
                customer.balance = Decimal(customer.balance) + credit_amount
                if payload.get("device_id"):
                    customer.device_id = str(payload.get("device_id"))
                db.add(customer)
        LedgerService.record_sale(db, sale, credit_component=credit_amount)

    @staticmethod
    def _apply_event(db: Session, store_id: str, entity: str, operation: str, payload: dict) -> None:
        if entity == "product":
            SyncService._apply_product_event(db, store_id, operation, payload)
            return
        if entity == "customer":
            SyncService._apply_customer_event(db, store_id, operation, payload)
            return
        if entity == "customer_payment":
            SyncService._apply_customer_payment_event(db, store_id, operation, payload)
            return
        if entity == "expense":
            SyncService._apply_expense_event(db, store_id, operation, payload)
            return
        if entity == "sale":
            SyncService._apply_sale_event(db, store_id, operation, payload)
            return
        raise SyncApplyError("UNSUPPORTED_ENTITY", f"Unsupported sync entity: {entity}")

    @staticmethod
    def _fingerprint(entity: str, operation: str, payload: dict) -> str:
        raw = json.dumps(
            {"entity": entity, "operation": operation, "payload": payload},
            sort_keys=True,
            separators=(",", ":"),
        )
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @staticmethod
    def _op_fingerprint(device_id: str, op_id: str) -> str:
        raw = json.dumps(
            {"device_id": device_id, "op_id": op_id},
            sort_keys=True,
            separators=(",", ":"),
        )
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @staticmethod
    def push(db: Session, store_id: str, payload: SyncPushRequest) -> SyncPushResponse:
        started = perf_counter()
        acked_op_ids: list[str] = []
        failed_events: list[SyncPushFailedEvent] = []
        duplicate_events = 0
        applied_events = 0
        for event in payload.events:
            event_payload = dict(event.payload)
            event_payload.setdefault("schema_version", 1)
            if event.device_id and "device_id" not in event_payload:
                event_payload["device_id"] = event.device_id

            if event.device_id and event.op_id:
                fingerprint = SyncService._op_fingerprint(event.device_id, event.op_id)
            else:
                fingerprint = SyncService._fingerprint(
                    event.entity,
                    event.operation,
                    event_payload,
                )
            existing = db.scalar(
                select(SyncEvent).where(
                    SyncEvent.store_id == store_id,
                    SyncEvent.fingerprint == fingerprint,
                )
            )
            if existing is not None:
                duplicate_events += 1
                if event.op_id:
                    acked_op_ids.append(event.op_id)
                continue
            try:
                with db.begin_nested():
                    SyncService._apply_event(db, store_id, event.entity, event.operation, event_payload)
                    db.add(
                        SyncEvent(
                            store_id=store_id,
                            entity=event.entity,
                            operation=event.operation,
                            fingerprint=fingerprint,
                            payload=event_payload,
                            created_at=datetime.now(UTC),
                        )
                    )
                applied_events += 1
                if event.op_id:
                    acked_op_ids.append(event.op_id)
            except SyncApplyError as exc:
                failed_events.append(
                    SyncPushFailedEvent(
                        op_id=event.op_id,
                        entity=event.entity,
                        operation=event.operation,
                        code=exc.code,
                        message=exc.message,
                    )
                )
            except Exception:
                failed_events.append(
                    SyncPushFailedEvent(
                        op_id=event.op_id,
                        entity=event.entity,
                        operation=event.operation,
                        code="APPLY_FAILED",
                        message="Failed to apply sync event",
                    )
                )
        db.commit()
        SyncService._log.info(
            "sync_push store_id=%s received=%d applied=%d duplicates=%d acked=%d failed=%d duration_ms=%d",
            store_id,
            len(payload.events),
            applied_events,
            duplicate_events,
            len(acked_op_ids),
            len(failed_events),
            int((perf_counter() - started) * 1000),
        )
        return SyncPushResponse(acked_op_ids=acked_op_ids, failed_events=failed_events)

    @staticmethod
    def pull(
        db: Session,
        store_id: str,
        since: datetime | None,
        cursor: str | None = None,
        *,
        limit: int = 200,
    ) -> SyncPullResponse:
        started = perf_counter()
        query = select(SyncEvent).where(SyncEvent.store_id == store_id)
        if cursor:
            cursor_event = db.scalar(
                select(SyncEvent).where(
                    SyncEvent.id == cursor,
                    SyncEvent.store_id == store_id,
                )
            )
            if cursor_event is not None:
                query = query.where(
                    or_(
                        SyncEvent.created_at > cursor_event.created_at,
                        and_(
                            SyncEvent.created_at == cursor_event.created_at,
                            SyncEvent.id > cursor_event.id,
                        ),
                    )
                )
            elif since is not None:
                query = query.where(SyncEvent.created_at > since)
        elif since is not None:
            query = query.where(SyncEvent.created_at > since)

        rows = db.scalars(
            query.order_by(SyncEvent.created_at.asc(), SyncEvent.id.asc()).limit(limit)
        ).all()
        response = SyncPullResponse(
            events=[
                SyncPullEvent(
                    id=row.id,
                    entity=row.entity,
                    operation=row.operation,
                    payload=row.payload,
                    created_at=row.created_at,
                )
                for row in rows
            ],
            next_cursor=rows[-1].id if rows else cursor,
        )
        SyncService._log.info(
            "sync_pull store_id=%s limit=%d cursor=%s since=%s returned=%d next_cursor=%s duration_ms=%d",
            store_id,
            limit,
            cursor or "-",
            since.isoformat() if since else "-",
            len(response.events),
            response.next_cursor or "-",
            int((perf_counter() - started) * 1000),
        )
        return response

    @staticmethod
    def status(db: Session, store_id: str) -> SyncStatusResponse:
        last_event = db.scalar(
            select(SyncEvent)
            .where(SyncEvent.store_id == store_id)
            .order_by(SyncEvent.created_at.desc())
        )
        return SyncStatusResponse(
            server_time=datetime.now(UTC),
            last_event_id=last_event.id if last_event is not None else None,
            # Fresh clients should do a full pull (since=None). Returning the latest
            # event timestamp here can cause them to miss historical data.
            recommended_pull_since=None,
        )
