from datetime import datetime

from pydantic import BaseModel, field_validator

UTC_TIMESTAMP_KEYS = {
    "created_at",
    "updated_at",
    "deleted_at",
    "registered_at",
    "last_seen_at",
    "expires_at",
    "resolved_at",
    "computed_at",
}


def _validate_sync_payload(value: object, *, path: str = "payload") -> None:
    if isinstance(value, dict):
        for key, nested in value.items():
            key_str = str(key)
            child_path = f"{path}.{key_str}"
            if key_str in UTC_TIMESTAMP_KEYS or key_str.endswith("_at"):
                if nested is None:
                    continue
                if not isinstance(nested, str):
                    raise ValueError(f"{child_path} must be an RFC3339 UTC string")
                try:
                    parsed = datetime.fromisoformat(nested.replace("Z", "+00:00"))
                except ValueError as exc:
                    raise ValueError(f"{child_path} must be an RFC3339 UTC string") from exc
                if parsed.tzinfo is None:
                    raise ValueError(f"{child_path} must include timezone information")
                if not nested.endswith("Z"):
                    raise ValueError(f"{child_path} must use UTC Z format")
            _validate_sync_payload(nested, path=child_path)
        return
    if isinstance(value, list):
        for idx, nested in enumerate(value):
            _validate_sync_payload(nested, path=f"{path}[{idx}]")


class SyncPushEvent(BaseModel):
    op_id: str | None = None
    device_id: str | None = None
    entity: str
    operation: str
    payload: dict

    @field_validator("payload")
    @classmethod
    def validate_payload_timestamps(cls, value: dict) -> dict:
        _validate_sync_payload(value)
        return value


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
