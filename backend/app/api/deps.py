from fastapi import Depends, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.errors import raise_api_error
from app.core.security import decode_token
from app.models.store import Store
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = decode_token(token)
    except ValueError:
        raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            "INVALID_AUTH_CREDENTIALS",
            "Invalid authentication credentials",
        )

    if payload.get("type") != "access":
        raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            "INVALID_TOKEN_TYPE",
            "Invalid token type",
        )

    user = db.scalar(select(User).where(User.id == payload.get("sub")))
    if user is None:
        raise_api_error(
            status.HTTP_401_UNAUTHORIZED,
            "USER_NOT_FOUND",
            "User not found",
        )
    return user


def get_current_store(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Store:
    store = db.scalar(select(Store).where(Store.owner_user_id == user.id))
    if store is None:
        raise_api_error(
            status.HTTP_404_NOT_FOUND,
            "STORE_NOT_FOUND",
            "Store not found for user",
        )
    return store


def require_roles(*allowed_roles: str):
    normalized = {role.strip().lower() for role in allowed_roles if role.strip()}

    def _dependency(user: User = Depends(get_current_user)) -> User:
        if normalized and str(getattr(user, "role", "owner")).lower() not in normalized:
            raise_api_error(
                status.HTTP_403_FORBIDDEN,
                "FORBIDDEN",
                "You do not have permission to access this resource",
            )
        return user

    return _dependency
