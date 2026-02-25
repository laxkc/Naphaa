from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.errors import raise_api_error
from app.core.rate_limit import auth_rate_limit
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.revoked_token import RevokedToken
from app.models.store import Store
from app.models.user import User
from app.schemas.user import (
    AuthProfileOut,
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LogoutRequest,
    MessageOut,
    RefreshTokenRequest,
    ResetPasswordRequest,
    TokenPair,
    UserLogin,
    UserRegister,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _revoke_refresh_token_if_needed(db: Session, refresh_token: str) -> None:
    token_hash = RevokedToken.hash_token(refresh_token)
    existing = db.scalar(select(RevokedToken).where(RevokedToken.token_hash == token_hash))
    if existing is not None:
        return
    token_data = decode_token(refresh_token)
    exp = token_data.get("exp")
    expires_at = datetime.fromtimestamp(exp, tz=UTC) if exp else datetime.now(UTC)
    db.add(
        RevokedToken(
            token_hash=token_hash,
            token_type="refresh",
            expires_at=expires_at,
        )
    )


@router.post("/register", response_model=TokenPair)
def register(
    payload: UserRegister,
    request: Request,
    _: None = Depends(auth_rate_limit),
    db: Session = Depends(get_db),
) -> TokenPair:
    device_id = request.headers.get("X-Device-Id")
    existing = db.scalar(select(User).where(User.phone == payload.phone))
    if existing is not None:
        raise_api_error(status.HTTP_409_CONFLICT, "PHONE_ALREADY_REGISTERED", "Phone already registered")

    user = User(phone=payload.phone, password_hash=hash_password(payload.password))
    db.add(user)
    db.commit()
    db.refresh(user)

    business_name = (payload.business_name or "").strip()
    if business_name:
        store = Store(
            owner_user_id=user.id,
            name=business_name,
            locale_default=(payload.locale_default or "ne").lower(),
            currency=payload.currency or "NPR",
            created_by=user.id,
            updated_by=user.id,
            device_id=device_id,
        )
        db.add(store)
        db.commit()

    return TokenPair(
        access_token=create_access_token(user.id, extra_claims={"role": user.role}),
        refresh_token=create_refresh_token(user.id, extra_claims={"role": user.role}),
    )


@router.post("/login", response_model=TokenPair)
def login(
    payload: UserLogin,
    _: None = Depends(auth_rate_limit),
    db: Session = Depends(get_db),
) -> TokenPair:
    user = db.scalar(select(User).where(User.phone == payload.phone))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_CREDENTIALS", "Invalid credentials")

    return TokenPair(
        access_token=create_access_token(user.id, extra_claims={"role": user.role}),
        refresh_token=create_refresh_token(user.id, extra_claims={"role": user.role}),
    )


@router.post("/refresh", response_model=TokenPair)
def refresh(payload: RefreshTokenRequest, db: Session = Depends(get_db)) -> TokenPair:
    try:
        token_data = decode_token(payload.refresh_token)
    except ValueError:
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_TOKEN", "Invalid token")

    token_hash = RevokedToken.hash_token(payload.refresh_token)
    revoked = db.scalar(select(RevokedToken).where(RevokedToken.token_hash == token_hash))
    if revoked is not None:
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "TOKEN_REVOKED", "Token has been revoked")

    if token_data.get("type") != "refresh":
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_TOKEN_TYPE", "Invalid token type")

    user = db.scalar(select(User).where(User.id == token_data.get("sub")))
    if user is None:
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "USER_NOT_FOUND", "User not found")

    # Rotate refresh token: revoke the submitted token and mint a new pair.
    _revoke_refresh_token_if_needed(db, payload.refresh_token)
    db.commit()

    return TokenPair(
        access_token=create_access_token(user.id, extra_claims={"role": user.role}),
        refresh_token=create_refresh_token(user.id, extra_claims={"role": user.role}),
    )


@router.get("/me", response_model=AuthProfileOut)
def auth_me(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AuthProfileOut:
    store = db.scalar(select(Store).where(Store.owner_user_id == user.id))
    return AuthProfileOut(
        user_id=user.id,
        phone=user.phone,
        role=user.role,
        store_id=store.id if store else None,
        store_name=store.name if store else None,
        store_address=store.address if store else None,
        store_phone=store.phone if store else None,
        business_type=store.business_type if store else None,
        locale_default=store.locale_default if store else None,
        currency=store.currency if store else None,
    )


@router.post("/logout", response_model=MessageOut)
def logout(payload: LogoutRequest, db: Session = Depends(get_db)) -> MessageOut:
    try:
        token_data = decode_token(payload.refresh_token)
    except ValueError:
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_TOKEN", "Invalid token")
    if token_data.get("type") != "refresh":
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_TOKEN_TYPE", "Invalid token type")

    _revoke_refresh_token_if_needed(db, payload.refresh_token)
    db.commit()
    return MessageOut(message="Logged out")


@router.post("/change-password", response_model=MessageOut)
def change_password(
    payload: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageOut:
    if not verify_password(payload.current_password, user.password_hash):
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_CURRENT_PASSWORD", "Current password is invalid")
    user.password_hash = hash_password(payload.new_password)
    db.add(user)
    db.commit()
    return MessageOut(message="Password changed")


@router.post("/forgot-password", response_model=MessageOut)
def forgot_password(payload: ForgotPasswordRequest) -> MessageOut:
    # Pilot placeholder endpoint. OTP delivery is intentionally out of scope for MVP.
    return MessageOut(message=f"Password reset is not enabled yet for {payload.phone}.")


@router.post("/reset-password", response_model=MessageOut)
def reset_password(payload: ResetPasswordRequest) -> MessageOut:
    # Pilot placeholder endpoint. OTP verification is intentionally out of scope for MVP.
    return MessageOut(message=f"Password reset is not enabled yet for {payload.phone}.")
