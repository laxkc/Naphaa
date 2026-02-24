from datetime import date, datetime, time

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_store
from app.core.database import get_db
from app.models.ledger_entry import LedgerEntry
from app.models.product import Product
from app.models.store import Store
from app.schemas.ledger import LedgerListResponse
from app.schemas.report import CashbookReport, LowStockItem, LowStockReport, SummaryReport, TopProductsReport
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/summary", response_model=SummaryReport)
def summary_report(
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> SummaryReport:
    date_from = datetime.combine(from_date, time.min) if from_date else None
    date_to = datetime.combine(to_date, time.max) if to_date else None
    return ReportService.summary(db, store.id, date_from, date_to)


@router.get("/low-stock", response_model=LowStockReport)
def low_stock_report(
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> LowStockReport:
    products = db.scalars(
        select(Product).where(
            Product.store_id == store.id,
            Product.is_deleted.is_(False),
            Product.is_active.is_(True),
            Product.stock_qty <= Product.low_stock_threshold,
        )
    ).all()
    return LowStockReport(
        items=[
            LowStockItem(
                product_id=p.id,
                name=p.name,
                stock_qty=p.stock_qty,
                low_stock_threshold=p.low_stock_threshold,
            )
            for p in products
        ]
    )


@router.get("/cashbook", response_model=CashbookReport)
def cashbook_report(
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> CashbookReport:
    return ReportService.cashbook(db, store.id)


@router.get("/top-products", response_model=TopProductsReport)
def top_products_report(
    limit: int = Query(default=10, ge=1, le=50),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> TopProductsReport:
    return ReportService.top_products(db, store.id, limit=limit)


@router.get("/ledger", response_model=LedgerListResponse)
def ledger_report(
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> LedgerListResponse:
    query = select(LedgerEntry).where(LedgerEntry.store_id == store.id)
    if from_date is not None:
        query = query.where(LedgerEntry.created_at >= datetime.combine(from_date, time.min))
    if to_date is not None:
        query = query.where(LedgerEntry.created_at <= datetime.combine(to_date, time.max))
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    offset = (page - 1) * page_size
    items = db.scalars(
        query.order_by(LedgerEntry.created_at.desc()).offset(offset).limit(page_size)
    ).all()
    return LedgerListResponse(items=items, total=total, page=page, page_size=page_size)
