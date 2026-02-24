from datetime import datetime

from pydantic import BaseModel


class SyncPushEvent(BaseModel):
    op_id: str | None = None
    device_id: str | None = None
    entity: str
    operation: str
    payload: dict


class SyncPushRequest(BaseModel):
    events: list[SyncPushEvent]


class SyncPushFailedEvent(BaseModel):
    op_id: str | None = None
    entity: str
    operation: str
    code: str
    message: str


class SyncPushResponse(BaseModel):
    acked_op_ids: list[str]
    failed_events: list[SyncPushFailedEvent] = []


class SyncPullEvent(BaseModel):
    id: str
    entity: str
    operation: str
    payload: dict
    created_at: datetime


class SyncPullResponse(BaseModel):
    events: list[SyncPullEvent]
    next_cursor: str | None = None


class SyncStatusResponse(BaseModel):
    server_time: datetime
    last_event_id: str | None
    recommended_pull_since: datetime | None
