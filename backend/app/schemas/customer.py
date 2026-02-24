from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class CustomerCreate(BaseModel):
    name: str
    phone: str | None = None


class CustomerUpdate(BaseModel):
    name: str | None = None
    phone: str | None = None


class CustomerOut(BaseModel):
    id: str
    store_id: str
    name: str
    phone: str | None
    balance: Decimal
    updated_at: datetime

    model_config = {"from_attributes": True}


class CustomerListResponse(BaseModel):
    items: list[CustomerOut]
    total: int
    page: int
    page_size: int


class CustomerPaymentCreate(BaseModel):
    amount: Decimal
    note: str | None = None
    method: str = "CASH"


class CustomerPaymentOut(BaseModel):
    id: str
    store_id: str
    customer_id: str
    method: str
    amount: Decimal
    note: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class CustomerLedgerItem(BaseModel):
    type: str
    amount: Decimal
    created_at: datetime
    ref_id: str
    note: str | None = None
    running_balance: Decimal


class CustomerLedgerResponse(BaseModel):
    items: list[CustomerLedgerItem]
    total: Decimal
    page: int
    page_size: int
