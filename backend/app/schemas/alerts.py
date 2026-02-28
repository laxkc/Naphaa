from datetime import datetime

from pydantic import BaseModel


class AlertOut(BaseModel):
    id: str
    type: str
    entity_type: str
    entity_id: str | None = None
    severity: str
    title: str
    body: str
    action_type: str | None = None
    action_payload: dict | None = None
    created_at: datetime
    resolved_at: datetime | None = None


class AlertsResponse(BaseModel):
    items: list[AlertOut]
    total: int
    computed_at: datetime
