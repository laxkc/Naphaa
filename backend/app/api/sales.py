from datetime import date

from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import get_current_store, get_current_user
from app.core.database import get_db
from app.core.errors import raise_api_error
from app.models.customer import Customer
from app.models.sale import Sale
from app.models.store import Store
from app.models.user import User
from app.models.sale_refund import SaleRefund
from app.schemas.sale import SaleCreate, SaleListResponse, SaleOut, SaleRefundCreate, SaleRefundOut
from app.services.sale_service import SaleService

router = APIRouter(prefix="/sales", tags=["sales"])


@router.post("", response_model=SaleOut)
def create_sale(
    payload: SaleCreate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Sale:
    if len(payload.items) == 0:
        raise_api_error(status.HTTP_400_BAD_REQUEST, "SALE_ITEMS_REQUIRED", "items is required")
    return SaleService.create_sale(
        db=db,
        store_id=store.id,
        payload=payload,
        actor_user_id=user.id,
        idempotency_key=idempotency_key,
        device_id=device_id,
    )


@router.get("", response_model=SaleListResponse)
def list_sales(
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    search: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> SaleListResponse:
    filters = [Sale.store_id == store.id]
    if from_date is not None:
        filters.append(Sale.sale_date_ad >= from_date)
    if to_date is not None:
        filters.append(Sale.sale_date_ad <= to_date)
    query = select(Sale).where(*filters)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = (
            query.outerjoin(Customer, Customer.id == Sale.customer_id)
            .where(
                or_(
                    Sale.id.ilike(term),
                    Customer.name.ilike(term),
                    Customer.phone.ilike(term),
                )
            )
        )
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    offset = (page - 1) * page_size
    items = db.scalars(
        query
        .options(selectinload(Sale.items), selectinload(Sale.payments))
        .order_by(Sale.sale_date_ad.desc(), Sale.created_at.desc())
        .offset(offset)
        .limit(page_size)
    ).all()
    return SaleListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/{sale_id}", response_model=SaleOut)
def get_sale(
    sale_id: str,
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> Sale:
    sale = db.scalar(
        select(Sale)
        .where(Sale.id == sale_id, Sale.store_id == store.id)
        .options(selectinload(Sale.items), selectinload(Sale.payments))
    )
    if sale is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "SALE_NOT_FOUND", "Sale not found")
    return sale


@router.post("/{sale_id}/refund", response_model=SaleRefundOut)
def refund_sale(
    sale_id: str,
    payload: SaleRefundCreate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> SaleRefund:
    return SaleService.refund_sale(
        db=db,
        store_id=store.id,
        sale_id=sale_id,
        payload=payload,
        actor_user_id=user.id,
        device_id=device_id,
    )
