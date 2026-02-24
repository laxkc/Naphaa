from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.customer_payment import CustomerPayment
from app.models.expense import Expense
from app.models.ledger_entry import LedgerEntry
from app.models.sale import Sale
from app.models.sale_refund import SaleRefund


class LedgerService:
    @staticmethod
    def _ensure_entry(
        db: Session,
        *,
        store_id: str,
        entity_type: str,
        entity_id: str,
        entry_type: str,
        direction: str,
        amount: Decimal,
        customer_id: str | None = None,
        sale_id: str | None = None,
        created_by: str | None = None,
        device_id: str | None = None,
        metadata_json: dict | None = None,
    ) -> None:
        existing = db.scalar(
            select(LedgerEntry).where(
                LedgerEntry.store_id == store_id,
                LedgerEntry.entity_type == entity_type,
                LedgerEntry.entity_id == entity_id,
                LedgerEntry.entry_type == entry_type,
            )
        )
        if existing is not None:
            return
        db.add(
            LedgerEntry(
                store_id=store_id,
                entity_type=entity_type,
                entity_id=entity_id,
                entry_type=entry_type,
                direction=direction,
                amount=amount,
                customer_id=customer_id,
                sale_id=sale_id,
                created_by=created_by,
                device_id=device_id,
                metadata_json=metadata_json,
            )
        )

    @staticmethod
    def record_sale(db: Session, sale: Sale, *, credit_component: Decimal | None = None) -> None:
        LedgerService._ensure_entry(
            db,
            store_id=sale.store_id,
            entity_type="sale",
            entity_id=sale.id,
            entry_type="sale",
            direction="IN",
            amount=Decimal(sale.total_amount),
            customer_id=sale.customer_id,
            sale_id=sale.id,
            created_by=sale.created_by,
            device_id=sale.device_id,
            metadata_json={
                "sale_type": sale.sale_type,
                "payment_method": sale.payment_method,
                "credit_component": str(credit_component if credit_component is not None else Decimal("0")),
            },
        )

    @staticmethod
    def record_expense(db: Session, expense: Expense) -> None:
        LedgerService._ensure_entry(
            db,
            store_id=expense.store_id,
            entity_type="expense",
            entity_id=expense.id,
            entry_type="expense",
            direction="OUT",
            amount=Decimal(expense.amount),
            created_by=expense.created_by,
            device_id=expense.device_id,
            metadata_json={"category": expense.category},
        )

    @staticmethod
    def record_customer_payment(db: Session, payment: CustomerPayment) -> None:
        LedgerService._ensure_entry(
            db,
            store_id=payment.store_id,
            entity_type="customer_payment",
            entity_id=payment.id,
            entry_type="customer_payment",
            direction="IN",
            amount=Decimal(payment.amount),
            customer_id=payment.customer_id,
            created_by=payment.created_by,
            device_id=payment.device_id,
            metadata_json={"method": payment.method, "note": payment.note},
        )

    @staticmethod
    def record_refund(
        db: Session,
        refund: SaleRefund,
        *,
        customer_id: str | None = None,
        sale_id: str | None = None,
    ) -> None:
        LedgerService._ensure_entry(
            db,
            store_id=refund.store_id,
            entity_type="sale_refund",
            entity_id=refund.id,
            entry_type="refund",
            direction="OUT",
            amount=Decimal(refund.amount),
            customer_id=customer_id,
            sale_id=sale_id or refund.sale_id,
            created_by=refund.created_by,
            device_id=refund.device_id,
            metadata_json={"reason": refund.reason},
        )

