from datetime import date, datetime
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, Field


class SaleType(str, Enum):
    CASH = "CASH"
    CREDIT = "CREDIT"
    MIXED = "MIXED"


class PaymentMethod(str, Enum):
    CASH = "CASH"
    QR = "QR"
    BANK = "BANK"
    CREDIT = "CREDIT"


class SaleItemCreate(BaseModel):
    product_id: str
    qty: Decimal = Field(gt=0)
    unit_price: Decimal = Field(gt=0)


class SaleCreate(BaseModel):
    sale_type: SaleType
    payment_method: PaymentMethod | None = None
    customer_id: str | None = None
    items: list[SaleItemCreate]
    payments: list["SalePaymentCreate"] | None = None


class SaleItemOut(BaseModel):
    id: str
    sale_id: str
    product_id: str
    qty: Decimal
    unit_price: Decimal
    line_total: Decimal

    model_config = {"from_attributes": True}


class SaleOut(BaseModel):
    id: str
    store_id: str
    sale_type: str
    payment_method: str | None = None
    customer_id: str | None
    total_amount: Decimal
    sale_date_ad: date | None = None
    created_at: datetime
    updated_at: datetime
    items: list[SaleItemOut]
    payments: list["SalePaymentOut"] = []

    model_config = {"from_attributes": True}


class SaleListResponse(BaseModel):
    items: list[SaleOut]
    total: int
    page: int
    page_size: int


class SalePaymentCreate(BaseModel):
    method: PaymentMethod
    amount: Decimal = Field(gt=0)


class SalePaymentOut(BaseModel):
    id: str
    sale_id: str
    method: str
    amount: Decimal
    created_at: datetime

    model_config = {"from_attributes": True}


class SaleRefundItemCreate(BaseModel):
    product_id: str | None = None
    sale_item_id: str | None = None
    qty: Decimal = Field(gt=0)


class SaleRefundCreate(BaseModel):
    items: list[SaleRefundItemCreate] | None = None
    reason: str | None = None


class SaleRefundItemOut(BaseModel):
    id: str
    refund_id: str
    sale_id: str
    product_id: str
    qty: Decimal
    unit_price: Decimal
    line_total: Decimal

    model_config = {"from_attributes": True}


class SaleRefundOut(BaseModel):
    id: str
    store_id: str
    sale_id: str
    amount: Decimal
    refund_date_ad: date | None = None
    reason: str | None
    created_at: datetime
    items: list[SaleRefundItemOut]

    model_config = {"from_attributes": True}
