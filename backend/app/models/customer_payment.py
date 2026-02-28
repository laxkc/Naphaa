import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class CustomerPayment(Base):
    __tablename__ = "customer_payments"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), index=True)
    customer_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("customers.id"), index=True
    )
    method: Mapped[str] = mapped_column(String(24), default="CASH")
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    payment_date_ad: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    customer = relationship("Customer", back_populates="payments")
    store = relationship("Store", back_populates="customer_payments")
