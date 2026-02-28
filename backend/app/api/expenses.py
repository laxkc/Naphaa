from datetime import UTC, date, datetime

from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_store, get_current_user
from app.core.calendar import business_date_from_timestamp
from app.core.database import get_db
from app.core.errors import raise_api_error
from app.models.expense import Expense
from app.models.store import Store
from app.models.user import User
from app.schemas.expense import ExpenseCreate, ExpenseListResponse, ExpenseOut
from app.services.ledger_service import LedgerService
from app.services.sync_event_service import SyncEventService

router = APIRouter(prefix="/expenses", tags=["expenses"])


@router.post("", response_model=ExpenseOut)
def create_expense(
    payload: ExpenseCreate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Expense:
    expense = Expense(
        store_id=store.id,
        expense_date_ad=business_date_from_timestamp(
            value=None,
            timezone_name=store.business_timezone,
        ),
        created_by=user.id,
        updated_by=user.id,
        device_id=device_id,
        **payload.model_dump(),
    )
    db.add(expense)
    db.flush()
    LedgerService.record_expense(db, expense)
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="expense",
        operation="UPSERT",
        payload=SyncEventService.expense_payload(expense),
    )
    db.commit()
    db.refresh(expense)
    return expense


@router.get("", response_model=ExpenseListResponse)
def list_expenses(
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> ExpenseListResponse:
    query = select(Expense).where(
        Expense.store_id == store.id,
        Expense.deleted_at.is_(None),
    )
    if from_date is not None:
        query = query.where(Expense.expense_date_ad >= from_date)
    if to_date is not None:
        query = query.where(Expense.expense_date_ad <= to_date)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.where(Expense.note.ilike(term))
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    offset = (page - 1) * page_size
    items = db.scalars(
        query.order_by(Expense.expense_date_ad.desc(), Expense.created_at.desc()).offset(offset).limit(page_size)
    ).all()
    return ExpenseListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/{expense_id}", response_model=ExpenseOut)
def get_expense(
    expense_id: str,
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> Expense:
    expense = db.scalar(
        select(Expense).where(
            Expense.id == expense_id,
            Expense.store_id == store.id,
            Expense.deleted_at.is_(None),
        )
    )
    if expense is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "EXPENSE_NOT_FOUND", "Expense not found")
    return expense


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(
    expense_id: str,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> None:
    expense = db.scalar(
        select(Expense).where(
            Expense.id == expense_id,
            Expense.store_id == store.id,
            Expense.deleted_at.is_(None),
        )
    )
    if expense is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "EXPENSE_NOT_FOUND", "Expense not found")

    expense.deleted_at = datetime.now(UTC)
    expense.updated_by = user.id
    expense.device_id = device_id
    db.add(expense)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="expense",
        operation="DELETE",
        payload={
            "schema_version": 1,
            "id": expense.id,
            "deleted_at": expense.deleted_at or datetime.now(UTC),
            "device_id": device_id,
        },
    )
    db.commit()
