from datetime import datetime

from pydantic import BaseModel


class DeviceRegisterRequest(BaseModel):
    device_id: str
    device_model: str | None = None
    platform: str = "unknown"
    app_version: str | None = None


class DeviceOut(BaseModel):
    device_id: str
    owner_user_id: str
    device_model: str | None
    platform: str
    app_version: str | None
    registered_at: datetime
    last_seen_at: datetime

    model_config = {"from_attributes": True}
