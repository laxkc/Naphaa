from urllib.parse import quote_plus

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str
    api_v1_prefix: str
    app_port: int
    debug: bool

    database_url: str | None = None
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str
    db_sslmode: str

    jwt_secret_key: str
    jwt_algorithm: str
    access_token_expire_minutes: int
    refresh_token_expire_minutes: int
    cors_allowed_origins: list[str]
    sync_pull_default_limit: int
    sync_pull_max_limit: int
    auth_rate_limit_max_requests: int
    auth_rate_limit_window_seconds: int
    default_business_timezone: str
    default_calendar_mode: str

    model_config = SettingsConfigDict(
        env_file=(".env", ".env.development"),
        case_sensitive=False,
    )

    @property
    def effective_database_url(self) -> str:
        if self.database_url:
            return self.database_url
        password = quote_plus(self.db_password)
        return (
            f"postgresql+psycopg2://{self.db_user}:{password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
            f"?sslmode={self.db_sslmode}"
        )


settings = Settings()
