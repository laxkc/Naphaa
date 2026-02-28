from datetime import datetime

from pydantic import BaseModel

from app.core.calendar import DEFAULT_BUSINESS_TIMEZONE, DEFAULT_CALENDAR_MODE


class StoreCreate(BaseModel):
    name: str
    address: str | None = None
    phone: str | None = None
    business_type: str | None = None
    locale_default: str | None = None
    currency: str = "NPR"
    business_timezone: str = DEFAULT_BUSINESS_TIMEZONE
    calendar_mode: str = DEFAULT_CALENDAR_MODE


class StoreUpdate(BaseModel):
    name: str | None = None
    address: str | None = None
    phone: str | None = None
    business_type: str | None = None
    locale_default: str | None = None
    currency: str | None = None
    business_timezone: str | None = None
    calendar_mode: str | None = None


class StoreOut(BaseModel):
    id: str
    owner_user_id: str
    name: str
    address: str | None = None
    phone: str | None = None
    business_type: str | None = None
    locale_default: str
    currency: str
    business_timezone: str
    calendar_mode: str
    created_at: datetime

    model_config = {"from_attributes": True}
