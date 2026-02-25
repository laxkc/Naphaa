from decimal import Decimal

from pydantic import BaseModel


class AgingBucketBreakdown(BaseModel):
    d0_7: Decimal = Decimal("0")
    d8_30: Decimal = Decimal("0")
    d31_60: Decimal = Decimal("0")
    d60_plus: Decimal = Decimal("0")


class CustomerRiskFactorsOut(BaseModel):
    oldest_due_factor: float
    avg_days_to_pay_factor: float
    late_behavior_factor: float
    outstanding_spike_factor: float


class CustomerMetricOut(BaseModel):
    customer_id: str
    customer_name: str
    phone: str | None = None
    outstanding_amount: Decimal
    oldest_due_days: int
    avg_days_to_pay: Decimal
    on_time_rate: Decimal
    payment_frequency_30d: Decimal
    risk_score: int
    risk_level: str
    aging: AgingBucketBreakdown
    factors: CustomerRiskFactorsOut
    computed_at: str | None = None


class CustomerMetricsResponse(BaseModel):
    items: list[CustomerMetricOut]
    totals: AgingBucketBreakdown
    total_outstanding: Decimal
    total_overdue: Decimal
    high_risk_count: int
    computed_at: str


class ProductMetricOut(BaseModel):
    product_id: str
    product_name: str
    stock_qty: Decimal
    cost_price: Decimal | None = None
    qty_sold_7d: Decimal
    qty_sold_30d: Decimal
    revenue_30d: Decimal
    profit_30d: Decimal | None = None
    last_sale_at: str | None = None
    dead_stock: bool
    dead_stock_value: Decimal | None = None
    computed_at: str


class ProductMetricsResponse(BaseModel):
    items: list[ProductMetricOut]
    total_products: int
    dead_stock_count: int
    dead_stock_value_total: Decimal
    computed_at: str


class BusinessMetricsResponse(BaseModel):
    period_start: str | None = None
    period_end: str | None = None
    sales_total: Decimal
    expenses_total: Decimal
    profit_est: Decimal
    profit_margin: Decimal
    outstanding_total: Decimal
    overdue_total: Decimal
    cash_risk_level: str
    cash_horizon_days: int = 7
    expected_incoming_soon: Decimal = Decimal("0")
    expected_outgoing_soon: Decimal = Decimal("0")
    net_cash_outlook_soon: Decimal = Decimal("0")
    low_stock_count: int
    dead_stock_count: int
    high_risk_customers: int
    open_alerts_count: int
    computed_at: str
    reasons: list[str] = []
