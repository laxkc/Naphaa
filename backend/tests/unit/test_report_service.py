from datetime import datetime
from decimal import Decimal

from app.models.customer import Customer
from app.models.expense import Expense
from app.models.sale import Sale
from app.services.report_service import ReportService


def test_summary_report_aggregation(db_session):
    db_session.add_all(
        [
            Sale(store_id="store-1", sale_type="CASH", total_amount=Decimal("1000")),
            Sale(store_id="store-1", sale_type="CASH", total_amount=Decimal("500")),
            Expense(store_id="store-1", category="rent", amount=Decimal("300")),
            Customer(store_id="store-1", name="Sita", balance=Decimal("150")),
        ]
    )
    db_session.commit()

    summary = ReportService.summary(db_session, "store-1", None, None)

    assert summary.total_sales == Decimal("1500")
    assert summary.total_expenses == Decimal("300")
    assert summary.estimated_profit == Decimal("1200")
    assert summary.credit_outstanding == Decimal("150")


def test_summary_report_with_date_filter(db_session):
    now = datetime.now()
    db_session.add(
        Sale(
            store_id="store-1",
            sale_type="CASH",
            total_amount=Decimal("200"),
            created_at=now,
            sale_date_ad=now.date(),
        )
    )
    db_session.commit()

    summary = ReportService.summary(db_session, "store-1", now.date(), now.date())
    assert summary.total_sales == Decimal("200")
