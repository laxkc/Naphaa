from datetime import datetime

from pydantic import BaseModel


class StoreCreate(BaseModel):
    name: str
    locale_default: str | None = None
    currency: str = "NPR"


class StoreUpdate(BaseModel):
    name: str | None = None
    locale_default: str | None = None
    currency: str | None = None


class StoreOut(BaseModel):
    id: str
    owner_user_id: str
    name: str
    locale_default: str
    currency: str
    created_at: datetime

    model_config = {"from_attributes": True}
