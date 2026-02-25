import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Store(Base):
    __tablename__ = "stores"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(200))
    address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    business_type: Mapped[str | None] = mapped_column(String(64), nullable=True)
    locale_default: Mapped[str] = mapped_column(String(16), default="ne")
    currency: Mapped[str] = mapped_column(String(8), default="NPR")
    created_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", back_populates="stores")
    products = relationship("Product", back_populates="store", cascade="all, delete-orphan")
    customers = relationship("Customer", back_populates="store", cascade="all, delete-orphan")
    sales = relationship("Sale", back_populates="store", cascade="all, delete-orphan")
    expenses = relationship("Expense", back_populates="store", cascade="all, delete-orphan")
    customer_payments = relationship(
        "CustomerPayment",
        cascade="all, delete-orphan",
        back_populates="store",
    )
