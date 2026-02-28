from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models.alert import Alert
from app.models.customer import Customer
from app.models.customer_metric import CustomerMetric
from app.models.customer_payment import CustomerPayment
from app.models.product import Product
from app.models.expense import Expense
from app.models.sale import Sale
from app.models.sale import SaleItem


@dataclass(frozen=True)
class CustomerRiskFactors:
    oldest_due_factor: float
    avg_days_to_pay_factor: float
    late_behavior_factor: float
    outstanding_spike_factor: float


@dataclass(frozen=True)
class CustomerRiskResult:
    outstanding_amount: Decimal
    oldest_due_days: int
    avg_days_to_pay: Decimal
    on_time_rate: Decimal
    payment_frequency_30d: Decimal
    risk_score: int
    risk_level: str
    factors: CustomerRiskFactors


class IntelligenceService:
    """IR v1 deterministic metrics/risk helpers (initial skeleton).

    This service is introduced in IR0/IR1 to stabilize formulas/contracts before
    wiring full endpoint/UI functionality. IR2 will fill in the DB queries and
    computations using the same method signatures.
    """

    CUSTOMER_METRICS_VERSION = 1
    _ON_TIME_DAYS = 7
    _AVG_PAY_SAMPLE_SIZE = 20

    @staticmethod
    def clamp01(value: float) -> float:
        if value < 0:
            return 0.0
        if value > 1:
            return 1.0
        return value

    @staticmethod
    def score_customer_risk(
        *,
        outstanding_amount: Decimal,
        oldest_due_days: int,
        avg_days_to_pay: Decimal,
        on_time_rate: Decimal,
        avg_invoice_amount: Decimal | None,
        payment_frequency_30d: Decimal = Decimal("0"),
    ) -> CustomerRiskResult:
        """Rule-based v1 risk score from the spec (IR0 contract)."""
        avg_invoice = avg_invoice_amount or Decimal("0")
        a = IntelligenceService.clamp01(float(max(oldest_due_days, 0)) / 60.0)
        b = IntelligenceService.clamp01(float(max(avg_days_to_pay, Decimal("0"))) / 30.0)
        c = IntelligenceService.clamp01(1.0 - float(on_time_rate))
        if avg_invoice > 0:
            d = IntelligenceService.clamp01(float(outstanding_amount / (avg_invoice * Decimal("3"))))
        else:
            d = 0.0
        score = round(100 * ((0.40 * a) + (0.25 * b) + (0.25 * c) + (0.10 * d)))
        if score < 35:
            level = "green"
        elif score <= 65:
            level = "yellow"
        else:
            level = "red"
        return CustomerRiskResult(
            outstanding_amount=outstanding_amount,
            oldest_due_days=max(oldest_due_days, 0),
            avg_days_to_pay=max(avg_days_to_pay, Decimal("0")),
            on_time_rate=max(Decimal("0"), min(on_time_rate, Decimal("1"))),
            payment_frequency_30d=max(payment_frequency_30d, Decimal("0")),
            risk_score=max(0, min(score, 100)),
            risk_level=level,
            factors=CustomerRiskFactors(
                oldest_due_factor=a,
                avg_days_to_pay_factor=b,
                late_behavior_factor=c,
                outstanding_spike_factor=d,
            ),
        )

    @staticmethod
    def upsert_customer_metric(
        db: Session,
        *,
        store_id: str,
        customer_id: str,
        metric: CustomerRiskResult,
        computed_at: datetime | None = None,
    ) -> CustomerMetric:
        """IR1 persistence helper; IR2 caller will provide computed values."""
        ts = computed_at or datetime.now(UTC)
        row = (
            db.query(CustomerMetric)
            .filter(
                CustomerMetric.store_id == store_id,
                CustomerMetric.customer_id == customer_id,
            )
            .one_or_none()
        )
        explanation = {
            "oldest_due_factor": metric.factors.oldest_due_factor,
            "avg_days_to_pay_factor": metric.factors.avg_days_to_pay_factor,
            "late_behavior_factor": metric.factors.late_behavior_factor,
            "outstanding_spike_factor": metric.factors.outstanding_spike_factor,
        }
        if row is None:
            row = CustomerMetric(
                store_id=store_id,
                customer_id=customer_id,
            )
        row.outstanding_amount = metric.outstanding_amount
        row.oldest_due_days = metric.oldest_due_days
        row.avg_days_to_pay = metric.avg_days_to_pay
        row.on_time_rate = metric.on_time_rate
        row.payment_frequency_30d = metric.payment_frequency_30d
        row.risk_score = metric.risk_score
        row.risk_level = metric.risk_level
        row.explanation_json = explanation
        row.version = IntelligenceService.CUSTOMER_METRICS_VERSION
        row.computed_at = ts
        db.add(row)
        return row

    @staticmethod
    def replace_open_alerts(
        db: Session,
        *,
        store_id: str,
        alerts: list[dict],
        computed_at: datetime | None = None,
    ) -> list[Alert]:
        """IR1 persistence helper for generated alerts.

        IR2 will narrow this to per-alert-type regeneration; for now keep a safe
        explicit helper used by future metrics recomputation jobs.
        """
        ts = computed_at or datetime.now(UTC)
        db.execute(
            delete(Alert).where(
                Alert.store_id == store_id,
                Alert.resolved_at.is_(None),
            )
        )
        rows: list[Alert] = []
        for raw in alerts:
            row = Alert(
                store_id=store_id,
                type=str(raw.get("type") or "generic"),
                entity_type=str(raw.get("entity_type") or "business"),
                entity_id=(str(raw.get("entity_id")) if raw.get("entity_id") else None),
                severity=str(raw.get("severity") or "info"),
                title=str(raw.get("title") or "Alert"),
                body=str(raw.get("body") or ""),
                action_type=(str(raw.get("action_type")) if raw.get("action_type") else None),
                action_payload_json=raw.get("action_payload_json")
                if isinstance(raw.get("action_payload_json"), dict)
                else None,
                created_at=ts,
            )
            db.add(row)
            rows.append(row)
        return rows

    @staticmethod
    def _as_utc(dt: datetime | str | None) -> datetime:
        if dt is None:
            return datetime.now(UTC)
        if isinstance(dt, str):
            parsed = datetime.fromisoformat(dt.replace("Z", "+00:00"))
            if parsed.tzinfo is None:
                return parsed.replace(tzinfo=UTC)
            return parsed.astimezone(UTC)
        if dt.tzinfo is None:
            return dt.replace(tzinfo=UTC)
        return dt.astimezone(UTC)

    @staticmethod
    def _days_between(start: datetime, end: datetime) -> int:
        start_utc = IntelligenceService._as_utc(start)
        end_utc = IntelligenceService._as_utc(end)
        return max((end_utc.date() - start_utc.date()).days, 0)

    @staticmethod
    def _business_date(value: date | datetime | str | None) -> date:
        if isinstance(value, date) and not isinstance(value, datetime):
            return value
        return IntelligenceService._as_utc(value).date()

    @staticmethod
    def _days_between_dates(start: date | datetime | str | None, end: date | datetime | str | None) -> int:
        start_date = IntelligenceService._business_date(start)
        end_date = IntelligenceService._business_date(end)
        return max((end_date - start_date).days, 0)

    @staticmethod
    def _bucket_add(totals: dict[str, Decimal], age_days: int, amount: Decimal) -> None:
        if amount <= 0:
            return
        if age_days <= 7:
            totals["d0_7"] += amount
        elif age_days <= 30:
            totals["d8_30"] += amount
        elif age_days <= 60:
            totals["d31_60"] += amount
        else:
            totals["d60_plus"] += amount

    @staticmethod
    def compute_customer_metrics(db: Session, store_id: str) -> dict:
        now = datetime.now(UTC)
        customers = db.scalars(
            select(Customer).where(
                Customer.store_id == store_id,
                Customer.is_deleted.is_(False),
            )
        ).all()
        credit_sales = db.scalars(
            select(Sale)
            .where(
                Sale.store_id == store_id,
                Sale.sale_type == "CREDIT",
                Sale.customer_id.is_not(None),
            )
            .order_by(Sale.customer_id.asc(), Sale.sale_date_ad.asc(), Sale.created_at.asc())
        ).all()
        payments = db.scalars(
            select(CustomerPayment)
            .where(CustomerPayment.store_id == store_id)
            .order_by(
                CustomerPayment.customer_id.asc(),
                CustomerPayment.payment_date_ad.asc(),
                CustomerPayment.created_at.asc(),
            )
        ).all()

        sales_by_customer: dict[str, list[Sale]] = {}
        for sale in credit_sales:
            if not sale.customer_id:
                continue
            sales_by_customer.setdefault(sale.customer_id, []).append(sale)

        payments_by_customer: dict[str, list[CustomerPayment]] = {}
        for payment in payments:
            payments_by_customer.setdefault(payment.customer_id, []).append(payment)

        all_bucket_totals = {
            "d0_7": Decimal("0"),
            "d8_30": Decimal("0"),
            "d31_60": Decimal("0"),
            "d60_plus": Decimal("0"),
        }
        items: list[dict] = []

        for customer in customers:
            customer_sales = sales_by_customer.get(customer.id, [])
            customer_payments = payments_by_customer.get(customer.id, [])
            payment_remaining = [
                {
                    "amount": Decimal(p.amount or 0),
                    "payment_date": p.payment_date_ad or IntelligenceService._as_utc(p.created_at).date(),
                }
                for p in customer_payments
            ]
            payment_idx = 0

            buckets = {
                "d0_7": Decimal("0"),
                "d8_30": Decimal("0"),
                "d31_60": Decimal("0"),
                "d60_plus": Decimal("0"),
            }
            oldest_due_days = 0
            paid_sale_days: list[int] = []
            on_time_paid_count = 0
            total_paid_sales_count = 0
            avg_invoice_sum = Decimal("0")
            avg_invoice_count = 0

            for sale in customer_sales:
                sale_total = Decimal(sale.total_amount or 0)
                avg_invoice_sum += sale_total
                avg_invoice_count += 1
                remaining = sale_total
                sale_date = sale.sale_date_ad or IntelligenceService._as_utc(sale.created_at).date()
                last_payment_date: date | None = None

                while remaining > 0 and payment_idx < len(payment_remaining):
                    bucket = payment_remaining[payment_idx]
                    if bucket["amount"] <= 0:
                        payment_idx += 1
                        continue
                    consume = min(remaining, bucket["amount"])
                    remaining -= consume
                    bucket["amount"] -= consume
                    last_payment_date = bucket["payment_date"]
                    if bucket["amount"] <= 0:
                        payment_idx += 1

                if remaining > 0:
                    age_days = IntelligenceService._days_between_dates(sale_date, now.date())
                    IntelligenceService._bucket_add(buckets, age_days, remaining)
                    oldest_due_days = max(oldest_due_days, age_days)
                else:
                    paid_days = IntelligenceService._days_between_dates(
                        sale_date,
                        last_payment_date or now.date(),
                    )
                    paid_sale_days.append(paid_days)
                    total_paid_sales_count += 1
                    if paid_days <= IntelligenceService._ON_TIME_DAYS:
                        on_time_paid_count += 1

            outstanding_amount = sum(buckets.values(), Decimal("0"))
            avg_days_to_pay = (
                Decimal(sum(paid_sale_days[-IntelligenceService._AVG_PAY_SAMPLE_SIZE :]))
                / Decimal(min(len(paid_sale_days), IntelligenceService._AVG_PAY_SAMPLE_SIZE))
                if paid_sale_days
                else Decimal("14")
            )
            on_time_rate = (
                Decimal(on_time_paid_count) / Decimal(total_paid_sales_count)
                if total_paid_sales_count > 0
                else Decimal("0")
            )
            payment_frequency_30d = Decimal(
                sum(
                    1
                    for p in customer_payments
                    if IntelligenceService._days_between_dates(
                        p.payment_date_ad or p.created_at,
                        now.date(),
                    )
                    <= 30
                )
            )
            avg_invoice_amount = (
                avg_invoice_sum / Decimal(avg_invoice_count)
                if avg_invoice_count > 0
                else Decimal("0")
            )

            risk = IntelligenceService.score_customer_risk(
                outstanding_amount=outstanding_amount,
                oldest_due_days=oldest_due_days,
                avg_days_to_pay=avg_days_to_pay,
                on_time_rate=on_time_rate,
                avg_invoice_amount=avg_invoice_amount,
                payment_frequency_30d=payment_frequency_30d,
            )
            IntelligenceService.upsert_customer_metric(
                db,
                store_id=store_id,
                customer_id=customer.id,
                metric=risk,
                computed_at=now,
            )

            for key, value in buckets.items():
                all_bucket_totals[key] += value

            items.append(
                {
                    "customer_id": customer.id,
                    "customer_name": customer.name,
                    "phone": customer.phone,
                    "outstanding_amount": risk.outstanding_amount,
                    "oldest_due_days": risk.oldest_due_days,
                    "avg_days_to_pay": risk.avg_days_to_pay,
                    "on_time_rate": risk.on_time_rate,
                    "payment_frequency_30d": risk.payment_frequency_30d,
                    "risk_score": risk.risk_score,
                    "risk_level": risk.risk_level,
                    "aging": buckets,
                    "factors": {
                        "oldest_due_factor": risk.factors.oldest_due_factor,
                        "avg_days_to_pay_factor": risk.factors.avg_days_to_pay_factor,
                        "late_behavior_factor": risk.factors.late_behavior_factor,
                        "outstanding_spike_factor": risk.factors.outstanding_spike_factor,
                    },
                    "computed_at": now.isoformat(),
                }
            )

        db.flush()
        total_outstanding = sum((item["outstanding_amount"] for item in items), Decimal("0"))
        total_overdue = (
            all_bucket_totals["d8_30"] + all_bucket_totals["d31_60"] + all_bucket_totals["d60_plus"]
        )
        high_risk_count = sum(1 for item in items if item["risk_level"] == "red")

        return {
            "items": items,
            "totals": all_bucket_totals,
            "total_outstanding": total_outstanding,
            "total_overdue": total_overdue,
            "high_risk_count": high_risk_count,
            "computed_at": now.isoformat(),
        }

    @staticmethod
    def generate_credit_risk_alerts_from_customer_metrics(
        *,
        store_id: str,
        customer_metrics: dict,
        now: datetime | None = None,
    ) -> list[dict]:
        ts = IntelligenceService._as_utc(now)
        alerts: list[dict] = []
        for item in customer_metrics.get("items", []):
            outstanding = Decimal(item.get("outstanding_amount") or 0)
            if outstanding <= 0:
                continue
            oldest_due_days = int(item.get("oldest_due_days") or 0)
            risk_level = str(item.get("risk_level") or "green").lower()
            if oldest_due_days <= 7 and risk_level != "red":
                continue

            severity = "critical" if risk_level == "red" or oldest_due_days > 30 else "warn"
            customer_name = str(item.get("customer_name") or "Customer")
            customer_id = str(item.get("customer_id") or "")
            title = (
                f"{customer_name} credit overdue ({oldest_due_days}d)"
                if oldest_due_days > 0
                else f"{customer_name} credit risk alert"
            )
            body = (
                f"{customer_name} owes NPR {outstanding:.2f}. "
                f"Oldest unpaid credit is {oldest_due_days} day(s). "
                f"Risk score {int(item.get('risk_score') or 0)}."
            )
            alerts.append(
                {
                    "type": "credit_overdue",
                    "entity_type": "customer",
                    "entity_id": customer_id or None,
                    "severity": severity,
                    "title": title,
                    "body": body,
                    "action_type": "open_customer",
                    "action_payload_json": {"customer_id": customer_id} if customer_id else None,
                    "generated_at": ts.isoformat(),
                }
            )
        return alerts

    @staticmethod
    def compute_and_cache_open_alerts(db: Session, store_id: str) -> dict:
        """IR6 v1 slice: deterministic open alerts from current customer metrics."""
        metrics = IntelligenceService.compute_customer_metrics(db, store_id)
        now = datetime.now(UTC)
        alerts_payload = IntelligenceService.generate_credit_risk_alerts_from_customer_metrics(
            store_id=store_id,
            customer_metrics=metrics,
            now=now,
        )
        alerts_payload.extend(
            IntelligenceService.generate_expense_spike_alerts(
                db,
                store_id=store_id,
                now=now,
            )
        )
        rows = IntelligenceService.replace_open_alerts(
            db,
            store_id=store_id,
            alerts=alerts_payload,
            computed_at=now,
        )
        db.flush()
        return {
            "items": rows,
            "computed_at": now.isoformat(),
        }

    @staticmethod
    def generate_expense_spike_alerts(
        db: Session,
        *,
        store_id: str,
        now: datetime | None = None,
        spike_ratio_threshold: float = 1.3,
        min_threshold_amount: Decimal = Decimal("500"),
    ) -> list[dict]:
        ts = IntelligenceService._as_utc(now)
        expenses = db.scalars(
            select(Expense).where(
                Expense.store_id == store_id,
                Expense.deleted_at.is_(None),
            )
        ).all()
        if not expenses:
            return []

        current_week_start = ts.date().toordinal() - (ts.weekday())
        # buckets: -4,-3,-2,-1,0 (weeks relative to current week)
        category_weekly: dict[str, dict[int, Decimal]] = {}
        for e in expenses:
            expense_date = e.expense_date_ad or IntelligenceService._as_utc(e.created_at).date()
            week_start = expense_date.toordinal() - expense_date.weekday()
            week_delta = (week_start - current_week_start) // 7
            if week_delta < -4 or week_delta > 0:
                continue
            category = str(e.category or "OTHER").upper()
            category_weekly.setdefault(category, {i: Decimal("0") for i in range(-4, 1)})
            category_weekly[category][week_delta] += Decimal(e.amount or 0)

        alerts: list[dict] = []
        for category, weekly in category_weekly.items():
            current_week = weekly.get(0, Decimal("0"))
            prev_weeks = [weekly.get(i, Decimal("0")) for i in (-4, -3, -2, -1)]
            avg_4w = sum(prev_weeks, Decimal("0")) / Decimal("4")
            if avg_4w <= 0:
                continue
            if current_week <= min_threshold_amount:
                continue
            ratio = float(current_week / avg_4w) if avg_4w > 0 else 0.0
            if ratio <= spike_ratio_threshold:
                continue
            pct = round((ratio - 1.0) * 100)
            alerts.append(
                {
                    "type": "expense_spike",
                    "entity_type": "business",
                    "entity_id": None,
                    "severity": "warn" if ratio < 2.0 else "critical",
                    "title": f"Expense spike: {category.title()} +{pct}%",
                    "body": (
                        f"{category.title()} spending is NPR {current_week:.2f} this week "
                        f"vs avg NPR {avg_4w:.2f} over the previous 4 weeks."
                    ),
                    "action_type": "view_report",
                    "action_payload_json": {"report": "expenses", "category": category},
                    "generated_at": ts.isoformat(),
                }
            )
        return alerts

    @staticmethod
    def compute_product_metrics(
        db: Session,
        store_id: str,
        *,
        window_days: int = 30,
        dead_stock_days: int = 30,
    ) -> dict:
        now = datetime.now(UTC)
        products = db.scalars(
            select(Product).where(
                Product.store_id == store_id,
                Product.is_deleted.is_(False),
                Product.is_active.is_(True),
            )
        ).all()
        product_map = {p.id: p for p in products}
        if not product_map:
            return {
                "items": [],
                "total_products": 0,
                "dead_stock_count": 0,
                "dead_stock_value_total": Decimal("0"),
                "computed_at": now.isoformat(),
            }

        sales = db.scalars(
            select(Sale)
            .where(
                Sale.store_id == store_id,
                Sale.deleted_at.is_(None),
            )
            .order_by(Sale.sale_date_ad.asc(), Sale.created_at.asc())
        ).all()
        sale_map = {s.id: s for s in sales}
        sale_cutoff = now.date().toordinal() - max(window_days, 0)
        sale_cutoff_7d = now.date().toordinal() - 7

        sale_items = db.scalars(
            select(SaleItem).where(SaleItem.sale_id.in_(list(sale_map.keys()))) if sale_map else select(SaleItem).where(False)
        ).all()

        qty_sold_7d: dict[str, Decimal] = {pid: Decimal("0") for pid in product_map}
        qty_sold_30d: dict[str, Decimal] = {pid: Decimal("0") for pid in product_map}
        revenue_30d: dict[str, Decimal] = {pid: Decimal("0") for pid in product_map}
        profit_30d: dict[str, Decimal] = {pid: Decimal("0") for pid in product_map}
        last_sale_at: dict[str, datetime] = {}

        for item in sale_items:
            sale = sale_map.get(item.sale_id)
            if sale is None:
                continue
            pid = item.product_id
            if pid not in product_map:
                continue
            sale_dt = IntelligenceService._as_utc(sale.created_at)
            sale_date = sale.sale_date_ad or sale_dt.date()
            prev = last_sale_at.get(pid)
            if prev is None or sale_dt > prev:
                last_sale_at[pid] = sale_dt
            qty = Decimal(item.qty or 0)
            line_total = Decimal(item.line_total or 0)
            if sale_date.toordinal() >= sale_cutoff_7d:
                qty_sold_7d[pid] += qty
            if sale_date.toordinal() < sale_cutoff:
                continue
            qty_sold_30d[pid] += qty
            revenue_30d[pid] += line_total
            cost_price = product_map[pid].cost_price
            if cost_price is not None:
                profit_30d[pid] += line_total - (qty * Decimal(cost_price))

        items: list[dict] = []
        dead_stock_count = 0
        dead_stock_value_total = Decimal("0")
        for p in products:
            last_sale = last_sale_at.get(p.id)
            has_stock = Decimal(p.stock_qty or 0) > 0
            age_days = (
                IntelligenceService._days_between(last_sale, now)
                if last_sale is not None
                else dead_stock_days + 1
            )
            dead_stock = bool(has_stock and age_days > max(dead_stock_days, 0))
            dead_stock_value = None
            if dead_stock and p.cost_price is not None:
                dead_stock_value = Decimal(p.stock_qty or 0) * Decimal(p.cost_price)
                dead_stock_value_total += dead_stock_value
            if dead_stock:
                dead_stock_count += 1
            items.append(
                {
                    "product_id": p.id,
                    "product_name": p.name,
                    "stock_qty": Decimal(p.stock_qty or 0),
                    "cost_price": (Decimal(p.cost_price) if p.cost_price is not None else None),
                    "qty_sold_7d": qty_sold_7d.get(p.id, Decimal("0")),
                    "qty_sold_30d": qty_sold_30d.get(p.id, Decimal("0")),
                    "revenue_30d": revenue_30d.get(p.id, Decimal("0")),
                    "profit_30d": (
                        profit_30d.get(p.id, Decimal("0")) if p.cost_price is not None else None
                    ),
                    "last_sale_at": last_sale.isoformat() if last_sale else None,
                    "dead_stock": dead_stock,
                    "dead_stock_value": dead_stock_value,
                    "computed_at": now.isoformat(),
                }
            )

        items.sort(
            key=lambda row: (
                0 if row["dead_stock"] else 1,
                -float(row["qty_sold_7d"] or 0),
                -(float(row["profit_30d"]) if row["profit_30d"] is not None else -1e9),
                -(float(row["revenue_30d"]) if row["revenue_30d"] is not None else 0),
                row["product_name"].lower(),
            )
        )
        return {
            "items": items,
            "total_products": len(items),
            "dead_stock_count": dead_stock_count,
            "dead_stock_value_total": dead_stock_value_total,
            "computed_at": now.isoformat(),
        }
