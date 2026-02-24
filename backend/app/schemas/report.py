from decimal import Decimal

from pydantic import BaseModel


class SummaryReport(BaseModel):
    total_sales: Decimal
    total_expenses: Decimal
    estimated_profit: Decimal
    credit_outstanding: Decimal


class LowStockItem(BaseModel):
    product_id: str
    name: str
    stock_qty: Decimal
    low_stock_threshold: Decimal


class LowStockReport(BaseModel):
    items: list[LowStockItem]


class CashbookReport(BaseModel):
    cash_total: Decimal
    qr_total: Decimal
    bank_total: Decimal
    credit_total: Decimal


class TopProductItem(BaseModel):
    product_id: str
    name: str
    qty_sold: Decimal
    revenue: Decimal


class TopProductsReport(BaseModel):
    items: list[TopProductItem]
