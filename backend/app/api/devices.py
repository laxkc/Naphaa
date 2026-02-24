from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.device import Device
from app.models.user import User
from app.schemas.device import DeviceOut, DeviceRegisterRequest

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("/register", response_model=DeviceOut)
def register_device(
    payload: DeviceRegisterRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Device:
    existing = db.scalar(select(Device).where(Device.device_id == payload.device_id))
    if existing is None:
        device = Device(
            device_id=payload.device_id,
            owner_user_id=user.id,
            device_model=payload.device_model,
            platform=payload.platform,
            app_version=payload.app_version,
        )
        db.add(device)
        db.commit()
        db.refresh(device)
        return device

    existing.owner_user_id = user.id
    existing.device_model = payload.device_model
    existing.platform = payload.platform
    existing.app_version = payload.app_version
    db.add(existing)
    db.commit()
    db.refresh(existing)
    return existing


@router.get("", response_model=list[DeviceOut])
def list_devices(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Device]:
    return db.scalars(
        select(Device).where(Device.owner_user_id == user.id).order_by(Device.last_seen_at.desc())
    ).all()
