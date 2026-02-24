from datetime import UTC, datetime, timedelta, timezone
from decimal import Decimal

from app.models.expense import Expense
from app.services.intelligence_service import IntelligenceService


def test_credit_aging_bucket_boundaries():
    totals = {
        "d0_7": Decimal("0"),
        "d8_30": Decimal("0"),
        "d31_60": Decimal("0"),
        "d60_plus": Decimal("0"),
    }
    for age in [0, 7]:
        IntelligenceService._bucket_add(totals, age, Decimal("10"))
    for age in [8, 30]:
        IntelligenceService._bucket_add(totals, age, Decimal("20"))
    for age in [31, 60]:
        IntelligenceService._bucket_add(totals, age, Decimal("30"))
    for age in [61, 90]:
        IntelligenceService._bucket_add(totals, age, Decimal("40"))

    assert totals["d0_7"] == Decimal("20")
    assert totals["d8_30"] == Decimal("40")
    assert totals["d31_60"] == Decimal("60")
    assert totals["d60_plus"] == Decimal("80")


def test_days_between_is_timezone_safe_by_date():
    start = datetime(2026, 2, 24, 23, 30, tzinfo=timezone(timedelta(hours=5, minutes=45)))
    end = datetime(2026, 2, 25, 0, 15, tzinfo=UTC)
    # Different offsets, but date delta should remain non-negative and deterministic.
    days = IntelligenceService._days_between(start, end)
    assert days in (0, 1)


def test_score_customer_risk_produces_expected_levels():
    green = IntelligenceService.score_customer_risk(
        outstanding_amount=Decimal("100"),
        oldest_due_days=2,
        avg_days_to_pay=Decimal("3"),
        on_time_rate=Decimal("0.95"),
        avg_invoice_amount=Decimal("500"),
    )
    yellow = IntelligenceService.score_customer_risk(
        outstanding_amount=Decimal("2000"),
        oldest_due_days=20,
        avg_days_to_pay=Decimal("18"),
        on_time_rate=Decimal("0.50"),
        avg_invoice_amount=Decimal("700"),
    )
    red = IntelligenceService.score_customer_risk(
        outstanding_amount=Decimal("25000"),
        oldest_due_days=75,
        avg_days_to_pay=Decimal("40"),
        on_time_rate=Decimal("0.10"),
        avg_invoice_amount=Decimal("1500"),
    )

    assert green.risk_level == "green"
    assert 0 <= green.risk_score < 35
    assert yellow.risk_level == "yellow"
    assert 35 <= yellow.risk_score <= 65
    assert red.risk_level == "red"
    assert 66 <= red.risk_score <= 100


def test_score_customer_risk_clamps_factor_ranges():
    result = IntelligenceService.score_customer_risk(
        outstanding_amount=Decimal("-100"),
        oldest_due_days=-10,
        avg_days_to_pay=Decimal("-5"),
        on_time_rate=Decimal("2.0"),
        avg_invoice_amount=Decimal("0"),
    )
    assert result.risk_score >= 0
    assert result.oldest_due_days == 0
    assert result.avg_days_to_pay == Decimal("0")
    assert result.on_time_rate == Decimal("1")
    assert result.factors.oldest_due_factor == 0
    assert result.factors.avg_days_to_pay_factor == 0


def test_generate_expense_spike_alerts_triggers_only_when_thresholds_met(db_session):
    store_id = "store-1"
    now = datetime(2026, 2, 24, 12, 0, tzinfo=UTC)

    # Previous 4 weeks average = 200/week
    for weeks_ago in (4, 3, 2, 1):
        db_session.add(
            Expense(
                store_id=store_id,
                category="TRANSPORT",
                amount=Decimal("200"),
                created_at=now - timedelta(days=weeks_ago * 7),
            )
        )

    # Current week spike > 1.3x and > threshold
    db_session.add(
        Expense(
            store_id=store_id,
            category="TRANSPORT",
            amount=Decimal("1200"),
            created_at=now - timedelta(days=1),
        )
    )

    # Current week but below threshold amount => should not alert
    db_session.add(
        Expense(
            store_id=store_id,
            category="TEA",
            amount=Decimal("100"),
            created_at=now - timedelta(days=1),
        )
    )
    db_session.commit()

    alerts = IntelligenceService.generate_expense_spike_alerts(
        db_session,
        store_id=store_id,
        now=now,
    )

    types = [a["type"] for a in alerts]
    assert "expense_spike" in types
    transport = next(a for a in alerts if a["type"] == "expense_spike")
    assert "Transport" in transport["title"]
    assert transport["action_type"] == "view_report"

