import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import JSON, DateTime, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id: Mapped[str] = mapped_column(String(36), index=True)
    entity_type: Mapped[str] = mapped_column(String(32), index=True)
    entity_id: Mapped[str] = mapped_column(String(36), index=True)
    entry_type: Mapped[str] = mapped_column(String(32), index=True)
    direction: Mapped[str] = mapped_column(String(8))
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    customer_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    sale_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    created_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(128), nullable=True)
    metadata_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)

