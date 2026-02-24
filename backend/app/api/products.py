from datetime import UTC, datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import asc, desc, func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_store, get_current_user
from app.core.database import get_db
from app.core.errors import raise_api_error
from app.models.product import Product
from app.models.sale import SaleItem
from app.models.stock_movement import StockMovement
from app.models.store import Store
from app.models.user import User
from app.schemas.product import (
    ProductCreate,
    ProductListResponse,
    ProductOut,
    StockHistoryResponse,
    ProductUpdate,
    StockAdjustmentRequest,
)
from app.services.sync_event_service import SyncEventService
from app.services.inventory_service import InventoryService

router = APIRouter(prefix="/products", tags=["products"])


@router.post("", response_model=ProductOut)
def create_product(
    payload: ProductCreate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Product:
    product = Product(
        store_id=store.id,
        created_by=user.id,
        updated_by=user.id,
        device_id=device_id,
        **payload.model_dump(),
    )
    db.add(product)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="product",
        operation="UPSERT",
        payload=SyncEventService.product_payload(product),
    )
    db.commit()
    db.refresh(product)
    return product


@router.get("", response_model=ProductListResponse)
def list_products(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    sort: str = Query(default="updated_at"),
    order: str = Query(default="desc"),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> ProductListResponse:
    filters = [
        Product.store_id == store.id,
        Product.is_deleted.is_(False),
    ]
    if search and search.strip():
        term = f"%{search.strip()}%"
        filters.append(Product.name.ilike(term))
    base_query = select(Product).where(*filters)
    total = db.scalar(select(func.count()).select_from(base_query.subquery())) or 0
    offset = (page - 1) * page_size
    sort_column = {
        "updated_at": Product.updated_at,
        "created_at": Product.created_at,
        "name": Product.name,
        "stock_qty": Product.stock_qty,
        "sell_price": Product.sell_price,
    }.get(sort, Product.updated_at)
    order_clause = asc(sort_column) if order.lower() == "asc" else desc(sort_column)
    items = db.scalars(
        base_query
        .order_by(order_clause)
        .offset(offset)
        .limit(page_size)
    ).all()
    return ProductListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/{product_id}", response_model=ProductOut)
def get_product(
    product_id: str,
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> Product:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.store_id == store.id,
            Product.is_deleted.is_(False),
        )
    )
    if product is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")
    return product


@router.patch("/{product_id}", response_model=ProductOut)
def update_product(
    product_id: str,
    payload: ProductUpdate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Product:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.store_id == store.id,
            Product.is_deleted.is_(False),
        )
    )
    if product is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    product.updated_by = user.id
    product.device_id = device_id

    db.add(product)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="product",
        operation="UPSERT",
        payload=SyncEventService.product_payload(product),
    )
    db.commit()
    db.refresh(product)
    return product


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    product_id: str,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> None:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.store_id == store.id,
            Product.is_deleted.is_(False),
        )
    )
    if product is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")

    linked_sale_item = db.scalar(select(SaleItem.id).where(SaleItem.product_id == product_id))
    if linked_sale_item is not None:
        raise_api_error(
            status.HTTP_409_CONFLICT,
            "PRODUCT_IN_USE",
            "Product cannot be deleted because it has linked sales.",
        )

    product.is_deleted = True
    product.deleted_at = datetime.now(UTC)
    product.updated_by = user.id
    product.device_id = device_id
    db.add(product)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="product",
        operation="DELETE",
        payload={
            "schema_version": 1,
            "id": product.id,
            "deleted_at": product.deleted_at or datetime.now(UTC),
            "device_id": device_id,
        },
    )
    db.commit()


@router.post("/{product_id}/adjust-stock", response_model=ProductOut)
def adjust_stock(
    product_id: str,
    payload: StockAdjustmentRequest,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Product:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.store_id == store.id,
            Product.is_deleted.is_(False),
        )
    )
    if product is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")

    if payload.reason.strip() == "":
        raise_api_error(status.HTTP_400_BAD_REQUEST, "ADJUSTMENT_REASON_REQUIRED", "reason is required")

    next_qty = InventoryService.adjust_stock(db, product, Decimal(payload.delta_qty))
    product.updated_by = user.id
    product.device_id = device_id
    db.add(
        StockMovement(
            store_id=store.id,
            product_id=product.id,
            movement_type="MANUAL_ADJUSTMENT",
            delta_qty=Decimal(payload.delta_qty),
            balance_after=next_qty,
            reason=payload.reason.strip(),
            reference_type="PRODUCT_ADJUSTMENT",
            reference_id=product.id,
            created_by=user.id,
            device_id=device_id,
        )
    )
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="product",
        operation="ADJUST_STOCK",
        payload={
            "schema_version": 1,
            "id": product.id,
            "delta_qty": payload.delta_qty,
            "reason": payload.reason.strip(),
            "updated_at": product.updated_at or datetime.now(UTC),
        },
    )
    db.commit()
    db.refresh(product)
    return product


@router.get("/{product_id}/stock-history", response_model=StockHistoryResponse)
def stock_history(
    product_id: str,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> StockHistoryResponse:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.store_id == store.id,
            Product.is_deleted.is_(False),
        )
    )
    if product is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found")

    query = (
        select(StockMovement)
        .where(
            StockMovement.store_id == store.id,
            StockMovement.product_id == product_id,
        )
        .order_by(StockMovement.created_at.desc())
    )
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    offset = (page - 1) * page_size
    rows = db.scalars(
        query
        .offset(offset)
        .limit(page_size)
    ).all()
    items = [
        {
            "type": row.movement_type,
            "ref_id": row.reference_id,
            "delta_qty": row.delta_qty,
            "created_at": row.created_at,
        }
        for row in rows
    ]
    return StockHistoryResponse(items=items, total=total, page=page, page_size=page_size)
