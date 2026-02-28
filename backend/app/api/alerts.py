from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_store
from app.core.database import get_db
from app.models.store import Store
from app.schemas.alerts import AlertOut, AlertsResponse
from app.services.intelligence_service import IntelligenceService

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("", response_model=AlertsResponse)
def list_alerts(
    status: str = Query(default="open"),
    limit: int = Query(default=100, ge=1, le=500),
    store: Store = Depends(get_current_store),
    db: Session = Depends(get_db),
) -> AlertsResponse:
    # IR6 v1: only open alerts are supported; keep API shape future-ready.
    if status.lower() != "open":
        return AlertsResponse(items=[], total=0, computed_at=IntelligenceService._as_utc(None))

    result = IntelligenceService.compute_and_cache_open_alerts(db, store.id)
    db.commit()
    rows = result["items"][:limit]

    return AlertsResponse(
        items=[
            AlertOut(
                id=row.id,
                type=row.type,
                entity_type=row.entity_type,
                entity_id=row.entity_id,
                severity=row.severity,
                title=row.title,
                body=row.body,
                action_type=row.action_type,
                action_payload=row.action_payload_json,
                created_at=IntelligenceService._as_utc(row.created_at),
                resolved_at=IntelligenceService._as_utc(row.resolved_at) if row.resolved_at else None,
            )
            for row in rows
        ],
        total=len(rows),
        computed_at=IntelligenceService._as_utc(result["computed_at"]),
    )
