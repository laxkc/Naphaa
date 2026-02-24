from datetime import datetime
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, field_validator


class ExpenseCategory(str, Enum):
    RENT = "RENT"
    TRANSPORT = "TRANSPORT"
    SALARY = "SALARY"
    UTILITIES = "UTILITIES"
    OTHER = "OTHER"


class ExpenseCreate(BaseModel):
    category: ExpenseCategory
    amount: Decimal
    note: str | None = None

    @field_validator("category", mode="before")
    @classmethod
    def normalize_category(cls, value: str | ExpenseCategory) -> str | ExpenseCategory:
        if isinstance(value, str):
            return value.strip().upper()
        return value


class ExpenseOut(BaseModel):
    id: str
    store_id: str
    category: ExpenseCategory
    amount: Decimal
    note: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ExpenseListResponse(BaseModel):
    items: list[ExpenseOut]
    total: int
    page: int
    page_size: int
