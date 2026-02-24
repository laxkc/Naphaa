from datetime import date, datetime, time
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_store
from app.core.database import get_db
from app.models.store import Store
from app.models.product import Product
from app.schemas.metrics import (
    AgingBucketBreakdown,
    BusinessMetricsResponse,
    CustomerMetricOut,
    CustomerMetricsResponse,
    ProductMetricOut,
    ProductMetricsResponse,
    CustomerRiskFactorsOut,
)
from app.services.intelligence_service import IntelligenceService
from app.services.report_service import ReportService

router = APIRouter(prefix="/metrics", tags=["metrics"])


@router.get("/customers", response_model=CustomerMetricsResponse)
def customer_metrics(
    overdue_only: bool = Query(default=False),
    high_risk_only: bool = Query(default=False),
    limit: int = Query(default=200, ge=1, le=1000),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> CustomerMetricsResponse:
    result = IntelligenceService.compute_customer_metrics(db, store.id)
    db.commit()

    items = result["items"]
    if overdue_only:
        items = [item for item in items if int(item["oldest_due_days"]) > 7]
    if high_risk_only:
        items = [item for item in items if str(item["risk_level"]).lower() == "red"]

    items.sort(
        key=lambda item: (
            0 if str(item["risk_level"]).lower() == "red" else 1 if str(item["risk_level"]).lower() == "yellow" else 2,
            -int(item["oldest_due_days"]),
            -float(item["outstanding_amount"] or 0),
            str(item["customer_name"]).lower(),
        )
    )
    items = items[:limit]

    metric_items = [
        CustomerMetricOut(
            customer_id=item["customer_id"],
            customer_name=item["customer_name"],
            phone=item.get("phone"),
            outstanding_amount=Decimal(item["outstanding_amount"]),
            oldest_due_days=int(item["oldest_due_days"]),
            avg_days_to_pay=Decimal(item["avg_days_to_pay"]),
            on_time_rate=Decimal(item["on_time_rate"]),
            payment_frequency_30d=Decimal(item["payment_frequency_30d"]),
            risk_score=int(item["risk_score"]),
            risk_level=str(item["risk_level"]),
            aging=AgingBucketBreakdown(**item["aging"]),
            factors=CustomerRiskFactorsOut(**item["factors"]),
            computed_at=item.get("computed_at"),
        )
        for item in items
    ]

    totals = AgingBucketBreakdown(**result["totals"])
    return CustomerMetricsResponse(
        items=metric_items,
        totals=totals,
        total_outstanding=Decimal(result["total_outstanding"]),
        total_overdue=Decimal(result["total_overdue"]),
        high_risk_count=int(result["high_risk_count"]),
        computed_at=str(result["computed_at"]),
    )


@router.get("/products", response_model=ProductMetricsResponse)
def product_metrics(
    dead_stock_only: bool = Query(default=False),
    limit: int = Query(default=200, ge=1, le=1000),
    window_days: int = Query(default=30, ge=1, le=365),
    dead_stock_days: int = Query(default=30, ge=0, le=365),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> ProductMetricsResponse:
    result = IntelligenceService.compute_product_metrics(
        db,
        store.id,
        window_days=window_days,
        dead_stock_days=dead_stock_days,
    )
    items = result["items"]
    if dead_stock_only:
        items = [item for item in items if bool(item["dead_stock"])]
    items = items[:limit]
    return ProductMetricsResponse(
        items=[
            ProductMetricOut(
                product_id=item["product_id"],
                product_name=item["product_name"],
                stock_qty=Decimal(item["stock_qty"]),
                cost_price=Decimal(item["cost_price"]) if item["cost_price"] is not None else None,
                qty_sold_7d=Decimal(item["qty_sold_7d"]),
                qty_sold_30d=Decimal(item["qty_sold_30d"]),
                revenue_30d=Decimal(item["revenue_30d"]),
                profit_30d=Decimal(item["profit_30d"]) if item["profit_30d"] is not None else None,
                last_sale_at=item.get("last_sale_at"),
                dead_stock=bool(item["dead_stock"]),
                dead_stock_value=Decimal(item["dead_stock_value"])
                if item["dead_stock_value"] is not None
                else None,
                computed_at=str(item["computed_at"]),
            )
            for item in items
        ],
        total_products=int(result["total_products"]),
        dead_stock_count=int(result["dead_stock_count"]),
        dead_stock_value_total=Decimal(result["dead_stock_value_total"]),
        computed_at=str(result["computed_at"]),
    )


@router.get("/business", response_model=BusinessMetricsResponse)
def business_metrics(
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> BusinessMetricsResponse:
    dt_from = datetime.combine(from_date, time.min) if from_date else None
    dt_to = datetime.combine(to_date, time.max) if to_date else None

    summary = ReportService.summary(db, store.id, dt_from, dt_to)
    customer_metrics = IntelligenceService.compute_customer_metrics(db, store.id)
    product_metrics_result = IntelligenceService.compute_product_metrics(db, store.id)
    alerts_result = IntelligenceService.compute_and_cache_open_alerts(db, store.id)
    db.commit()

    sales_total = Decimal(summary.total_sales)
    expenses_total = Decimal(summary.total_expenses)
    profit_est = Decimal(summary.estimated_profit)
    profit_margin = (
        (profit_est / sales_total * Decimal("100")) if sales_total > 0 else Decimal("0")
    )
    outstanding_total = Decimal(customer_metrics["total_outstanding"])
    overdue_total = Decimal(customer_metrics["total_overdue"])
    high_risk_customers = int(customer_metrics["high_risk_count"])
    low_stock_count = int(
        db.scalar(
            select(func.count())
            .select_from(Product)
            .where(
                Product.store_id == store.id,
                Product.is_deleted.is_(False),
                Product.is_active.is_(True),
                Product.low_stock_threshold > 0,
                Product.stock_qty <= Product.low_stock_threshold,
            )
        )
        or 0
    )
    dead_stock_count = int(product_metrics_result["dead_stock_count"])
    open_alerts_count = len(alerts_result["items"])

    reasons: list[str] = []
    cash_risk_level = "low"
    if overdue_total > Decimal("0"):
        reasons.append(f"Overdue credit NPR {overdue_total:.2f}")
    if high_risk_customers > 0:
        reasons.append(f"{high_risk_customers} high-risk customer(s)")
    if profit_est < 0:
        reasons.append("Estimated profit is negative for the selected period")
    if dead_stock_count > 0:
        reasons.append(f"{dead_stock_count} dead-stock item(s)")
    if overdue_total > sales_total and sales_total > 0:
        cash_risk_level = "high"
    elif overdue_total > Decimal("0") or profit_est < 0 or high_risk_customers > 0:
        cash_risk_level = "medium"
    if not reasons:
        reasons.append("No major risk signals detected")

    return BusinessMetricsResponse(
        period_start=from_date.isoformat() if from_date else None,
        period_end=to_date.isoformat() if to_date else None,
        sales_total=sales_total,
        expenses_total=expenses_total,
        profit_est=profit_est,
        profit_margin=profit_margin,
        outstanding_total=outstanding_total,
        overdue_total=overdue_total,
        cash_risk_level=cash_risk_level,
        low_stock_count=low_stock_count,
        dead_stock_count=dead_stock_count,
        high_risk_customers=high_risk_customers,
        open_alerts_count=open_alerts_count,
        computed_at=str(alerts_result["computed_at"]),
        reasons=reasons,
    )
