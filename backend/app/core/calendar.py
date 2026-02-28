from __future__ import annotations

from datetime import UTC, date, datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from app.core.config import settings

DEFAULT_BUSINESS_TIMEZONE = settings.default_business_timezone
DEFAULT_CALENDAR_MODE = settings.default_calendar_mode


def resolve_timezone(name: str | None) -> ZoneInfo:
    tz_name = (name or "").strip() or DEFAULT_BUSINESS_TIMEZONE
    try:
        return ZoneInfo(tz_name)
    except ZoneInfoNotFoundError:
        return ZoneInfo(DEFAULT_BUSINESS_TIMEZONE)


def ensure_utc(value: datetime | None) -> datetime:
    if value is None:
        return datetime.now(UTC)
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def business_date_from_timestamp(
    *,
    value: datetime | None,
    timezone_name: str | None,
) -> date:
    instant = ensure_utc(value)
    return instant.astimezone(resolve_timezone(timezone_name)).date()
