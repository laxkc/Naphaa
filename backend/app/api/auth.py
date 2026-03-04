from datetime import UTC, datetime, timedelta
import secrets

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.calendar import DEFAULT_BUSINESS_TIMEZONE, DEFAULT_CALENDAR_MODE
from app.core.config import settings
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
from app.models.otp_challenge import OtpChallenge
from app.models.revoked_token import RevokedToken
from app.models.store import Store
from app.models.user import User
from app.schemas.user import (
    AuthProfileOut,
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LogoutRequest,
    MessageOut,
    OtpRequestIn,
    OtpRequestOut,
    OtpVerifyIn,
    RefreshTokenRequest,
    ResetPasswordRequest,
    TokenPair,
    UserLogin,
    UserRegister,
)

router = APIRouter(prefix="/auth", tags=["auth"])
OTP_EXPIRE_MINUTES = 5
OTP_MAX_VERIFY_ATTEMPTS = 5
DEFAULT_STORE_NAME = "My Shop"


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


def _normalize_locale(locale_default: str | None) -> str:
    value = (locale_default or "ne").strip().lower()
    return "en" if value.startswith("en") else "ne"


def _generate_otp_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def _as_utc(value: datetime) -> datetime:
    return value if value.tzinfo is not None else value.replace(tzinfo=UTC)


def _ensure_store_for_user(
    db: Session,
    *,
    user: User,
    locale_default: str,
    device_id: str | None,
) -> None:
    existing_store = db.scalar(select(Store).where(Store.owner_user_id == user.id))
    if existing_store is not None:
        updated = False
        if not existing_store.locale_default:
            existing_store.locale_default = locale_default
            updated = True
        if not existing_store.currency:
            existing_store.currency = "NPR"
            updated = True
        if not existing_store.business_timezone:
            existing_store.business_timezone = DEFAULT_BUSINESS_TIMEZONE
            updated = True
        if not existing_store.calendar_mode:
            existing_store.calendar_mode = DEFAULT_CALENDAR_MODE
            updated = True
        if updated:
            existing_store.updated_by = user.id
            existing_store.device_id = device_id
            db.add(existing_store)
        return

    db.add(
        Store(
            owner_user_id=user.id,
            name=DEFAULT_STORE_NAME,
            locale_default=locale_default,
            currency="NPR",
            business_timezone=DEFAULT_BUSINESS_TIMEZONE,
            calendar_mode=DEFAULT_CALENDAR_MODE,
            created_by=user.id,
            updated_by=user.id,
            device_id=device_id,
        )
    )


@router.post("/otp/request", response_model=OtpRequestOut)
def request_otp(
    payload: OtpRequestIn,
    _: None = Depends(auth_rate_limit),
    db: Session = Depends(get_db),
) -> OtpRequestOut:
    locale_default = _normalize_locale(payload.locale_default)
    user = db.scalar(select(User).where(User.phone == payload.phone))
    db.execute(delete(OtpChallenge).where(OtpChallenge.phone == payload.phone))

    otp_code = _generate_otp_code()
    challenge = OtpChallenge(
        phone=payload.phone,
        otp_hash=hash_password(otp_code),
        locale_default=locale_default,
        expires_at=datetime.now(UTC) + timedelta(minutes=OTP_EXPIRE_MINUTES),
        is_new_user_hint=user is None,
    )
    db.add(challenge)
    db.commit()

    return OtpRequestOut(
        message="OTP sent",
        expires_in_seconds=OTP_EXPIRE_MINUTES * 60,
        is_new_user=user is None,
        otp_debug_code=otp_code if settings.debug else None,
    )


@router.post("/otp/verify", response_model=TokenPair)
def verify_otp(
    payload: OtpVerifyIn,
    request: Request,
    _: None = Depends(auth_rate_limit),
    db: Session = Depends(get_db),
) -> TokenPair:
    challenge = db.scalar(
        select(OtpChallenge)
        .where(OtpChallenge.phone == payload.phone)
        .order_by(OtpChallenge.created_at.desc())
    )
    if challenge is None or challenge.consumed_at is not None:
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "OTP_NOT_FOUND", "OTP challenge not found")
    if _as_utc(challenge.expires_at) < datetime.now(UTC):
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "OTP_EXPIRED", "OTP has expired")
    if challenge.verify_attempts >= OTP_MAX_VERIFY_ATTEMPTS:
        raise_api_error(status.HTTP_429_TOO_MANY_REQUESTS, "OTP_BLOCKED", "Too many OTP attempts")
    if not verify_password(payload.otp, challenge.otp_hash):
        challenge.verify_attempts += 1
        db.add(challenge)
        db.commit()
        if challenge.verify_attempts >= OTP_MAX_VERIFY_ATTEMPTS:
            raise_api_error(status.HTTP_429_TOO_MANY_REQUESTS, "OTP_BLOCKED", "Too many OTP attempts")
        raise_api_error(status.HTTP_401_UNAUTHORIZED, "INVALID_OTP", "Invalid OTP")

    challenge.consumed_at = datetime.now(UTC)
    db.add(challenge)

    locale_default = _normalize_locale(payload.locale_default or challenge.locale_default)
    user = db.scalar(select(User).where(User.phone == payload.phone))
    if user is None:
        user = User(phone=payload.phone, password_hash=hash_password(secrets.token_urlsafe(32)))
        db.add(user)
        db.flush()

    device_id = request.headers.get("X-Device-Id")
    _ensure_store_for_user(
        db,
        user=user,
        locale_default=locale_default,
        device_id=device_id,
    )
    db.commit()
    db.refresh(user)

    return TokenPair(
        access_token=create_access_token(user.id, extra_claims={"role": user.role}),
        refresh_token=create_refresh_token(user.id, extra_claims={"role": user.role}),
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
            business_timezone=DEFAULT_BUSINESS_TIMEZONE,
            calendar_mode=DEFAULT_CALENDAR_MODE,
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
        business_timezone=store.business_timezone if store else None,
        calendar_mode=store.calendar_mode if store else None,
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
