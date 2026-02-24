import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id: Mapped[str] = mapped_column(String(36), ForeignKey("stores.id"), index=True)
    type: Mapped[str] = mapped_column(String(32), index=True)
    entity_type: Mapped[str] = mapped_column(String(32), index=True)
    entity_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    severity: Mapped[str] = mapped_column(String(16), default="info", index=True)
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[str] = mapped_column(String(1000))
    action_type: Mapped[str | None] = mapped_column(String(64), nullable=True)
    action_payload_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)

