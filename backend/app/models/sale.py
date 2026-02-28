import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Sale(Base):
    __tablename__ = "sales"
    __table_args__ = (
        UniqueConstraint("store_id", "idempotency_key", name="uq_sale_store_idempotency"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), index=True)
    sale_type: Mapped[str] = mapped_column(String(16))
    payment_method: Mapped[str | None] = mapped_column(String(24), nullable=True)
    customer_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("customers.id"), nullable=True)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    sale_date_ad: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(72), nullable=True, index=True)
    created_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    store = relationship("Store", back_populates="sales")
    customer = relationship("Customer")
    items = relationship("SaleItem", back_populates="sale", cascade="all, delete-orphan")
    payments = relationship("SalePayment", back_populates="sale", cascade="all, delete-orphan")
    refunds = relationship("SaleRefund", back_populates="sale", cascade="all, delete-orphan")


class SaleItem(Base):
    __tablename__ = "sale_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    sale_id: Mapped[str] = mapped_column(String(36), ForeignKey("sales.id"), index=True)
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"))
    qty: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    line_total: Mapped[Decimal] = mapped_column(Numeric(12, 2))

    sale = relationship("Sale", back_populates="items")
    product = relationship("Product")
