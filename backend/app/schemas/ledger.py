from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class LedgerEntryOut(BaseModel):
    id: str
    entity_type: str
    entity_id: str
    entry_type: str
    direction: str
    amount: Decimal
    customer_id: str | None = None
    sale_id: str | None = None
    created_at: datetime
    metadata_json: dict | None = None

    model_config = {"from_attributes": True}


class LedgerListResponse(BaseModel):
    items: list[LedgerEntryOut]
    total: int
    page: int
    page_size: int

