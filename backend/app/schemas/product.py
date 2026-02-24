from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class ProductCreate(BaseModel):
    name: str
    sell_price: Decimal
    cost_price: Decimal | None = None
    stock_qty: Decimal = Decimal("0")
    low_stock_threshold: Decimal = Decimal("0")
    is_active: bool = True


class ProductUpdate(BaseModel):
    name: str | None = None
    sell_price: Decimal | None = None
    cost_price: Decimal | None = None
    stock_qty: Decimal | None = None
    low_stock_threshold: Decimal | None = None
    is_active: bool | None = None


class ProductOut(BaseModel):
    id: str
    store_id: str
    name: str
    sell_price: Decimal
    cost_price: Decimal | None
    stock_qty: Decimal
    low_stock_threshold: Decimal
    is_active: bool
    updated_at: datetime

    model_config = {"from_attributes": True}


class ProductListResponse(BaseModel):
    items: list[ProductOut]
    total: int
    page: int
    page_size: int


class StockAdjustmentRequest(BaseModel):
    delta_qty: Decimal
    reason: str


class StockMovementOut(BaseModel):
    type: str
    ref_id: str | None
    delta_qty: Decimal
    created_at: datetime


class StockHistoryResponse(BaseModel):
    items: list[StockMovementOut]
    total: int
    page: int
    page_size: int
