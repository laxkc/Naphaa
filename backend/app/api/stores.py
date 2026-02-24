from fastapi import APIRouter, Depends, Header, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.errors import raise_api_error
from app.models.store import Store
from app.models.user import User
from app.schemas.store import StoreCreate, StoreOut, StoreUpdate

router = APIRouter(prefix="/stores", tags=["stores"])


@router.post("", response_model=StoreOut)
def create_store(
    payload: StoreCreate,
    accept_language: str | None = Header(default=None, alias="Accept-Language"),
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Store:
    existing = db.scalar(select(Store).where(Store.owner_user_id == user.id))
    if existing is not None:
        raise_api_error(status.HTTP_409_CONFLICT, "STORE_ALREADY_EXISTS", "Store already exists")

    header_locale = accept_language.split(",")[0].strip().lower() if accept_language else "ne"
    locale_default = payload.locale_default or header_locale.split("-")[0]
    store = Store(
        owner_user_id=user.id,
        name=payload.name,
        locale_default=locale_default,
        currency=payload.currency,
        created_by=user.id,
        updated_by=user.id,
        device_id=device_id,
    )
    db.add(store)
    db.commit()
    db.refresh(store)
    return store


@router.get("/me", response_model=StoreOut)
def get_my_store(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Store:
    store = db.scalar(select(Store).where(Store.owner_user_id == user.id))
    if store is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "STORE_NOT_FOUND", "Store not found")
    return store


@router.patch("/{store_id}", response_model=StoreOut)
def update_store(
    store_id: str,
    payload: StoreUpdate,
    device_id: str | None = Header(default=None, alias="X-Device-Id"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Store:
    store = db.scalar(
        select(Store).where(Store.id == store_id, Store.owner_user_id == user.id)
    )
    if store is None:
        raise_api_error(status.HTTP_404_NOT_FOUND, "STORE_NOT_FOUND", "Store not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(store, field, value)
    store.updated_by = user.id
    store.device_id = device_id

    db.add(store)
    db.commit()
    db.refresh(store)
    return store
