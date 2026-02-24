from datetime import datetime
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.customer import Customer
from app.models.expense import Expense
from app.models.product import Product
from app.models.sale import Sale, SaleItem
from app.models.sale_payment import SalePayment
from app.schemas.report import CashbookReport, SummaryReport, TopProductItem, TopProductsReport


class ReportService:
    @staticmethod
    def summary(db: Session, store_id: str, date_from: datetime | None, date_to: datetime | None) -> SummaryReport:
        sale_query = select(func.coalesce(func.sum(Sale.total_amount), 0)).where(
            Sale.store_id == store_id
        )
        expense_query = select(func.coalesce(func.sum(Expense.amount), 0)).where(
            Expense.store_id == store_id
        )

        if date_from is not None:
            sale_query = sale_query.where(Sale.created_at >= date_from)
            expense_query = expense_query.where(Expense.created_at >= date_from)
        if date_to is not None:
            sale_query = sale_query.where(Sale.created_at <= date_to)
            expense_query = expense_query.where(Expense.created_at <= date_to)

        total_sales = Decimal(db.scalar(sale_query) or 0)
        total_expenses = Decimal(db.scalar(expense_query) or 0)

        credit_outstanding = Decimal(
            db.scalar(
                select(func.coalesce(func.sum(Customer.balance), 0)).where(
                    Customer.store_id == store_id
                )
            )
            or 0
        )

        return SummaryReport(
            total_sales=total_sales,
            total_expenses=total_expenses,
            estimated_profit=total_sales - total_expenses,
            credit_outstanding=credit_outstanding,
        )

    @staticmethod
    def cashbook(db: Session, store_id: str) -> CashbookReport:
        rows = db.execute(
            select(
                SalePayment.method,
                func.coalesce(func.sum(SalePayment.amount), 0),
            )
            .join(Sale, Sale.id == SalePayment.sale_id)
            .where(Sale.store_id == store_id)
            .group_by(SalePayment.method)
        ).all()
        totals = {str(method).upper(): Decimal(amount) for method, amount in rows}
        return CashbookReport(
            cash_total=totals.get("CASH", Decimal("0")),
            qr_total=totals.get("QR", Decimal("0")),
            bank_total=totals.get("BANK", Decimal("0")),
            credit_total=totals.get("CREDIT", Decimal("0")),
        )

    @staticmethod
    def top_products(db: Session, store_id: str, limit: int = 10) -> TopProductsReport:
        rows = db.execute(
            select(
                SaleItem.product_id,
                Product.name,
                func.coalesce(func.sum(SaleItem.qty), 0),
                func.coalesce(func.sum(SaleItem.line_total), 0),
            )
            .join(Sale, Sale.id == SaleItem.sale_id)
            .join(Product, Product.id == SaleItem.product_id)
            .where(Sale.store_id == store_id)
            .group_by(SaleItem.product_id, Product.name)
            .order_by(func.sum(SaleItem.line_total).desc())
            .limit(limit)
        ).all()
        return TopProductsReport(
            items=[
                TopProductItem(
                    product_id=product_id,
                    name=name,
                    qty_sold=Decimal(qty),
                    revenue=Decimal(revenue),
                )
                for product_id, name, qty, revenue in rows
            ]
        )
