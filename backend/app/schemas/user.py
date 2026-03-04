from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class UserRegister(BaseModel):
    phone: str = Field(min_length=10, max_length=15)
    password: str = Field(min_length=8, max_length=128)
    business_name: str | None = None
    locale_default: str | None = None
    currency: str | None = None

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, value: str) -> str:
        return value.strip()


class UserLogin(BaseModel):
    phone: str = Field(min_length=10, max_length=15)
    password: str = Field(min_length=8, max_length=128)

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, value: str) -> str:
        return value.strip()


class OtpRequestIn(BaseModel):
    phone: str = Field(min_length=10, max_length=15)
    locale_default: str | None = None

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, value: str) -> str:
        return value.strip()


class OtpVerifyIn(BaseModel):
    phone: str = Field(min_length=10, max_length=15)
    otp: str = Field(min_length=4, max_length=8)
    locale_default: str | None = None

    @field_validator("phone")
    @classmethod
    def normalize_phone(cls, value: str) -> str:
        return value.strip()


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=8, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class ForgotPasswordRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=15)


class ResetPasswordRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=15)
    otp: str = Field(min_length=4, max_length=8)
    new_password: str = Field(min_length=8, max_length=128)


class MessageOut(BaseModel):
    message: str


class OtpRequestOut(BaseModel):
    message: str
    expires_in_seconds: int
    is_new_user: bool
    otp_debug_code: str | None = None


class UserOut(BaseModel):
    id: str
    phone: str
    role: str
    created_at: datetime

    model_config = {"from_attributes": True}


class AuthProfileOut(BaseModel):
    user_id: str
    phone: str
    role: str = "owner"
    store_id: str | None = None
    store_name: str | None = None
    store_address: str | None = None
    store_phone: str | None = None
    business_type: str | None = None
    locale_default: str | None = None
    currency: str | None = None
    business_timezone: str | None = None
    calendar_mode: str | None = None
