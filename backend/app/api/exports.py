from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import get_current_store
from app.core.database import get_db
from app.models.customer import Customer
from app.models.expense import Expense
from app.models.product import Product
from app.models.sale import Sale
from app.models.store import Store

router = APIRouter(prefix="/exports", tags=["exports"])


@router.get("/full")
def export_full(
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> dict:
    products = db.scalars(
        select(Product).where(Product.store_id == store.id, Product.is_deleted.is_(False))
    ).all()
    customers = db.scalars(
        select(Customer).where(
            Customer.store_id == store.id,
            Customer.deleted_at.is_(None),
            Customer.is_deleted.is_(False),
        )
    ).all()
    sales = db.scalars(
        select(Sale)
        .where(Sale.store_id == store.id)
        .options(selectinload(Sale.items), selectinload(Sale.payments))
    ).all()
    expenses = db.scalars(select(Expense).where(Expense.store_id == store.id)).all()
    return {
        "store": {
            "id": store.id,
            "name": store.name,
            "locale_default": store.locale_default,
            "currency": store.currency,
            "created_at": store.created_at,
        },
        "products": [_model_dict(p) for p in products],
        "customers": [_model_dict(c) for c in customers],
        "sales": [
            {
                **_model_dict(s),
                "items": [_model_dict(i) for i in s.items],
                "payments": [_model_dict(p) for p in s.payments],
            }
            for s in sales
        ],
        "expenses": [_model_dict(e) for e in expenses],
    }


def _model_dict(obj) -> dict:
    payload = {column.name: getattr(obj, column.name) for column in obj.__table__.columns}
    for key, value in list(payload.items()):
        if isinstance(value, Decimal):
            payload[key] = float(value)
    return payload
