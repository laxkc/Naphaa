from datetime import datetime

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_store
from app.core.database import get_db
from app.models.store import Store
from app.schemas.sync import (
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResponse,
    SyncStatusResponse,
)
from app.services.sync_service import SyncService

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushResponse)
def sync_push(
    payload: SyncPushRequest,
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> SyncPushResponse:
    return SyncService.push(db, store.id, payload)


@router.get("/pull", response_model=SyncPullResponse)
def sync_pull(
    since: datetime | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=200, ge=1, le=1000),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> SyncPullResponse:
    return SyncService.pull(db, store.id, since, cursor, limit=limit)


@router.get("/status", response_model=SyncStatusResponse)
def sync_status(
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> SyncStatusResponse:
    return SyncService.status(db, store.id)
