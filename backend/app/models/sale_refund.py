import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class SaleRefund(Base):
    __tablename__ = "sale_refunds"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(String(36), index=True)
    sale_id: Mapped[str] = mapped_column(String(36), ForeignKey("sales.id"), index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    refund_date_ad: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    sale = relationship("Sale", back_populates="refunds")
    items = relationship(
        "SaleRefundItem",
        back_populates="refund",
        cascade="all, delete-orphan",
    )


class SaleRefundItem(Base):
    __tablename__ = "sale_refund_items"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    refund_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("sale_refunds.id"), index=True
    )
    sale_id: Mapped[str] = mapped_column(String(36), index=True)
    product_id: Mapped[str] = mapped_column(String(36), index=True)
    qty: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    line_total: Mapped[Decimal] = mapped_column(Numeric(12, 2))

    refund = relationship("SaleRefund", back_populates="items")
