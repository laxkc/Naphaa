import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import JSON, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class CustomerMetric(Base):
    __tablename__ = "customer_metrics"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), index=True)
    customer_id: Mapped[str] = mapped_column(String(36), ForeignKey("customers.id"), index=True)
    outstanding_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    oldest_due_days: Mapped[int] = mapped_column(default=0)
    avg_days_to_pay: Mapped[Decimal] = mapped_column(Numeric(8, 2), default=0)
    on_time_rate: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=0)
    payment_frequency_30d: Mapped[Decimal] = mapped_column(Numeric(8, 2), default=0)
    risk_score: Mapped[int] = mapped_column(default=0, index=True)
    risk_level: Mapped[str] = mapped_column(String(16), default="green", index=True)
    explanation_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    version: Mapped[int] = mapped_column(default=1)
    computed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        index=True,
    )
