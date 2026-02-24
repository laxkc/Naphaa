from datetime import UTC, datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import asc, desc, func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_store, get_current_user
from app.core.database import get_db
from app.core.errors import raise_api_error
from app.models.customer import Customer
from app.models.customer_payment import CustomerPayment
from app.models.sale import Sale
from app.models.sale_refund import SaleRefund
from app.models.store import Store
from app.models.user import User
from app.schemas.customer import (
    CustomerCreate,
    CustomerLedgerItem,
    CustomerLedgerResponse,
    CustomerListResponse,
    CustomerOut,
    CustomerPaymentCreate,
    CustomerPaymentOut,
    CustomerUpdate,
)
from app.services.ledger_service import LedgerService
from app.services.sync_event_service import SyncEventService

router = APIRouter(prefix="/customers", tags=["customers"])


@router.post("", response_model=CustomerOut)
def create_customer(
    payload: CustomerCreate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Customer:
    customer = Customer(
        store_id=store.id,
        created_by=user.id,
        updated_by=user.id,
        device_id=device_id,
        **payload.model_dump(),
    )
    db.add(customer)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer",
        operation="UPSERT",
        payload=SyncEventService.customer_payload(customer),
    )
    db.commit()
    db.refresh(customer)
    return customer


@router.get("", response_model=CustomerListResponse)
def list_customers(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    sort: str = Query(default="updated_at"),
    order: str = Query(default="desc"),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> CustomerListResponse:
    filters = [
        Customer.store_id == store.id,
        Customer.deleted_at.is_(None),
        Customer.is_deleted.is_(False),
    ]
    if search and search.strip():
        term = f"%{search.strip()}%"
        filters.append((Customer.name.ilike(term)) | (Customer.phone.ilike(term)))

    base_query = select(Customer).where(*filters)
    total = db.scalar(select(func.count()).select_from(base_query.subquery())) or 0
    offset = (page - 1) * page_size
    sort_column = {
        "updated_at": Customer.updated_at,
        "created_at": Customer.created_at,
        "name": Customer.name,
        "balance": Customer.balance,
    }.get(sort, Customer.updated_at)
    order_clause = asc(sort_column) if order.lower() == "asc" else desc(sort_column)
    items = db.scalars(
        base_query
        .order_by(order_clause)
        .offset(offset)
        .limit(page_size)
    ).all()
    return CustomerListResponse(items=items, total=total, page=page, page_size=page_size)


@router.get("/{customer_id}", response_model=CustomerOut)
def get_customer(
    customer_id: str,
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> Customer:
    customer = db.scalar(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.store_id == store.id,
            Customer.deleted_at.is_(None),
            Customer.is_deleted.is_(False),
        )
    )
    if customer is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")
    return customer


@router.patch("/{customer_id}", response_model=CustomerOut)
def update_customer(
    customer_id: str,
    payload: CustomerUpdate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> Customer:
    customer = db.scalar(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.store_id == store.id,
            Customer.deleted_at.is_(None),
            Customer.is_deleted.is_(False),
        )
    )
    if customer is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(customer, field, value)
    customer.updated_by = user.id
    customer.device_id = device_id

    db.add(customer)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer",
        operation="UPSERT",
        payload=SyncEventService.customer_payload(customer),
    )
    db.commit()
    db.refresh(customer)
    return customer


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_customer(
    customer_id: str,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> None:
    customer = db.scalar(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.store_id == store.id,
            Customer.deleted_at.is_(None),
            Customer.is_deleted.is_(False),
        )
    )
    if customer is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")
    if Decimal(customer.balance) > 0:
        raise_api_error(
            status.HTTP_409_CONFLICT,
            "CUSTOMER_HAS_BALANCE",
            "Cannot delete customer with outstanding balance",
        )

    customer.deleted_at = datetime.now(UTC)
    customer.is_deleted = True
    customer.updated_by = user.id
    customer.device_id = device_id
    db.add(customer)
    db.flush()
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer",
        operation="DELETE",
        payload={
            "schema_version": 1,
            "id": customer.id,
            "deleted_at": customer.deleted_at or datetime.now(UTC),
            "device_id": device_id,
        },
    )
    db.commit()


@router.post("/{customer_id}/payments", response_model=CustomerPaymentOut)
def create_customer_payment(
    customer_id: str,
    payload: CustomerPaymentCreate,
    store: Store = Depends(get_current_store),
    user: User = Depends(get_current_user),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    db: Session = Depends(get_db),
) -> CustomerPayment:
    customer = db.scalar(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.store_id == store.id,
            Customer.deleted_at.is_(None),
        )
    )
    if customer is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")

    amount = Decimal(payload.amount)
    if amount <= 0:
        raise_api_error(status.HTTP_400_BAD_REQUEST, "INVALID_PAYMENT_AMOUNT", "amount must be greater than zero")
    if amount > Decimal(customer.balance):
        raise_api_error(
            status.HTTP_400_BAD_REQUEST,
            "PAYMENT_EXCEEDS_BALANCE",
            "Payment amount cannot exceed customer balance",
        )

    payment = CustomerPayment(
        store_id=store.id,
        customer_id=customer.id,
        method=payload.method.upper(),
        amount=amount,
        note=payload.note,
        created_by=user.id,
        device_id=device_id,
    )
    customer.balance = Decimal(customer.balance) - amount
    customer.updated_by = user.id
    customer.device_id = device_id

    db.add(payment)
    db.add(customer)
    db.flush()
    LedgerService.record_customer_payment(db, payment)
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer_payment",
        operation="UPSERT",
        payload=SyncEventService.customer_payment_payload(payment),
    )
    SyncEventService.emit(
        db,
        store_id=store.id,
        entity="customer",
        operation="UPSERT",
        payload=SyncEventService.customer_payload(customer),
    )
    db.commit()
    db.refresh(payment)
    return payment


@router.get("/{customer_id}/ledger", response_model=CustomerLedgerResponse)
def customer_ledger(
    customer_id: str,
    from_date: datetime | None = Query(default=None, alias="from"),
    to_date: datetime | None = Query(default=None, alias="to"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> CustomerLedgerResponse:
    customer = db.scalar(
        select(Customer).where(
            Customer.id == customer_id,
            Customer.store_id == store.id,
            Customer.deleted_at.is_(None),
            Customer.is_deleted.is_(False),
        )
    )
    if customer is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")

    events: list[tuple[datetime, str, Decimal, str, str | None]] = []
    refunds = db.scalars(
        select(SaleRefund).join(Sale, Sale.id == SaleRefund.sale_id).where(
            SaleRefund.store_id == store.id,
            Sale.customer_id == customer_id,
            Sale.sale_type == "CREDIT",
        )
    ).all()
    refunded_by_sale: dict[str, Decimal] = {}
    for r in refunds:
        refunded_by_sale[r.sale_id] = refunded_by_sale.get(r.sale_id, Decimal("0")) + Decimal(r.amount)

    sales = db.scalars(
        select(Sale).where(
            Sale.store_id == store.id,
            Sale.customer_id == customer_id,
            Sale.sale_type == "CREDIT",
        )
    ).all()
    for s in sales:
        original_amount = Decimal(s.total_amount) + refunded_by_sale.get(s.id, Decimal("0"))
        events.append((s.created_at, "SALE", original_amount, s.id, None))

    payments = db.scalars(
        select(CustomerPayment).where(
            CustomerPayment.store_id == store.id,
            CustomerPayment.customer_id == customer_id,
        )
    ).all()
    for p in payments:
        events.append((p.created_at, "PAYMENT", Decimal(p.amount) * Decimal("-1"), p.id, p.note))

    for r in refunds:
        events.append((r.created_at, "REFUND", Decimal(r.amount) * Decimal("-1"), r.id, r.reason))

    events.sort(key=lambda it: it[0])
    if from_date is not None:
        events = [e for e in events if e[0] >= from_date]
    if to_date is not None:
        events = [e for e in events if e[0] <= to_date]

    total_count = len(events)
    start = (page - 1) * page_size
    end = start + page_size
    page_events = events[start:end]

    running = Decimal("0")
    for created_at, _, amount, _, _ in events[:start]:
        running += amount

    items: list[CustomerLedgerItem] = []
    for created_at, etype, amount, ref_id, note in page_events:
        running += amount
        items.append(
            CustomerLedgerItem(
                type=etype,
                amount=amount,
                created_at=created_at,
                ref_id=ref_id,
                note=note,
                running_balance=running,
            )
        )

    return CustomerLedgerResponse(
        items=items,
        total=Decimal(total_count),
        page=page,
        page_size=page_size,
    )
