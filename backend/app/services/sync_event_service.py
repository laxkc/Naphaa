from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
import hashlib
import json
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.customer import Customer
from app.models.customer_payment import CustomerPayment
from app.models.expense import Expense
from app.models.product import Product
from app.models.sale import Sale
from app.models.sync_event import SyncEvent


class SyncEventService:
    @staticmethod
    def _normalize(value: Any) -> Any:
        if isinstance(value, Decimal):
            return float(value)
        if isinstance(value, datetime):
            if value.tzinfo is None:
                value = value.replace(tzinfo=UTC)
            return value.isoformat()
        if isinstance(value, list):
            return [SyncEventService._normalize(v) for v in value]
        if isinstance(value, dict):
            return {str(k): SyncEventService._normalize(v) for k, v in value.items()}
        return value

    @staticmethod
    def _fingerprint(entity: str, operation: str, payload: dict[str, Any]) -> str:
        raw = json.dumps(
            {"entity": entity, "operation": operation.upper(), "payload": payload},
            sort_keys=True,
            separators=(",", ":"),
        )
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @staticmethod
    def emit(db: Session, *, store_id: str, entity: str, operation: str, payload: dict[str, Any]) -> None:
        normalized_payload = SyncEventService._normalize(payload)
        fingerprint = SyncEventService._fingerprint(entity, operation, normalized_payload)
        existing = db.scalar(
            select(SyncEvent).where(
                SyncEvent.store_id == store_id,
                SyncEvent.fingerprint == fingerprint,
            )
        )
        if existing is not None:
            return
        db.add(
            SyncEvent(
                store_id=store_id,
                entity=entity,
                operation=operation.upper(),
                fingerprint=fingerprint,
                payload=normalized_payload,
            )
        )

    @staticmethod
    def product_payload(product: Product) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "id": product.id,
            "name": product.name,
            "sell_price": product.sell_price,
            "cost_price": product.cost_price or 0,
            "stock_qty": product.stock_qty,
            "low_stock_threshold": product.low_stock_threshold,
            "is_active": bool(product.is_active) and not bool(product.is_deleted),
            "updated_at": product.updated_at or datetime.now(UTC),
        }

    @staticmethod
    def customer_payload(customer: Customer) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "id": customer.id,
            "name": customer.name,
            "phone": customer.phone,
            "balance": customer.balance,
            "updated_at": customer.updated_at or datetime.now(UTC),
            "is_deleted": bool(customer.is_deleted),
        }

    @staticmethod
    def customer_payment_payload(payment: CustomerPayment) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "id": payment.id,
            "customer_id": payment.customer_id,
            "method": payment.method,
            "amount": payment.amount,
            "payment_date_ad": payment.payment_date_ad.isoformat() if payment.payment_date_ad else None,
            "note": payment.note,
            "created_at": payment.created_at or datetime.now(UTC),
        }

    @staticmethod
    def expense_payload(expense: Expense) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "id": expense.id,
            "category": expense.category,
            "amount": expense.amount,
            "expense_date_ad": expense.expense_date_ad.isoformat() if expense.expense_date_ad else None,
            "note": expense.note,
            "created_at": expense.created_at or datetime.now(UTC),
        }

    @staticmethod
    def sale_payload(sale: Sale) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "id": sale.id,
            "sale_type": sale.sale_type,
            "payment_method": sale.payment_method or "CASH",
            "customer_id": sale.customer_id,
            "total_amount": sale.total_amount,
            "sale_date_ad": sale.sale_date_ad.isoformat() if sale.sale_date_ad else None,
            "created_at": sale.created_at or datetime.now(UTC),
            "items": [
                {
                    "product_id": item.product_id,
                    "qty": item.qty,
                    "unit_price": item.unit_price,
                }
                for item in sale.items
            ],
            "payments": [
                {
                    "id": p.id,
                    "method": p.method,
                    "amount": p.amount,
                    "created_at": p.created_at or datetime.now(UTC),
                }
                for p in sale.payments
            ],
        }
