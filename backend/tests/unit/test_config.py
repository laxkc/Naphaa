from pydantic import ValidationError

from app.core.config import Settings


def test_effective_database_url_is_built_from_env_fields(monkeypatch) -> None:
    monkeypatch.setenv("APP_NAME", "Naphaa API")
    monkeypatch.setenv("API_V1_PREFIX", "/api/v1")
    monkeypatch.setenv("APP_PORT", "8000")
    monkeypatch.setenv("DEBUG", "true")
    monkeypatch.setenv("ENABLE_API_DOCS", "true")
    monkeypatch.setenv("DB_HOST", "example.postgres.database.azure.com")
    monkeypatch.setenv("DB_PORT", "5432")
    monkeypatch.setenv("DB_NAME", "naphaa-database")
    monkeypatch.setenv("DB_USER", "naphaa-user")
    monkeypatch.setenv("DB_PASSWORD", r"o$kaULhF9$i$xsgI")
    monkeypatch.setenv("DB_SSLMODE", "require")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("REFRESH_TOKEN_EXPIRE_MINUTES", "10080")
    monkeypatch.setenv("CORS_ALLOWED_ORIGINS", '["*"]')
    monkeypatch.setenv("SYNC_PULL_DEFAULT_LIMIT", "100")
    monkeypatch.setenv("SYNC_PULL_MAX_LIMIT", "500")
    monkeypatch.setenv("AUTH_RATE_LIMIT_MAX_REQUESTS", "30")
    monkeypatch.setenv("AUTH_RATE_LIMIT_WINDOW_SECONDS", "60")
    monkeypatch.setenv("DEFAULT_BUSINESS_TIMEZONE", "Asia/Kathmandu")
    monkeypatch.setenv("DEFAULT_CALENDAR_MODE", "BS")

    settings = Settings(_env_file=None)

    assert settings.effective_database_url == (
        "postgresql+psycopg2://naphaa-user:o%24kaULhF9%24i%24xsgI"
        "@example.postgres.database.azure.com:5432/naphaa-database"
        "?sslmode=require"
    )
    assert settings.enable_api_docs is True


def test_database_url_override_takes_precedence(monkeypatch) -> None:
    monkeypatch.setenv("APP_NAME", "Naphaa API")
    monkeypatch.setenv("API_V1_PREFIX", "/api/v1")
    monkeypatch.setenv("APP_PORT", "8000")
    monkeypatch.setenv("DEBUG", "true")
    monkeypatch.setenv("ENABLE_API_DOCS", "false")
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg2://override")
    monkeypatch.setenv("DB_HOST", "unused-host")
    monkeypatch.setenv("DB_PORT", "5432")
    monkeypatch.setenv("DB_NAME", "unused-db")
    monkeypatch.setenv("DB_USER", "unused-user")
    monkeypatch.setenv("DB_PASSWORD", "unused-password")
    monkeypatch.setenv("DB_SSLMODE", "require")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("REFRESH_TOKEN_EXPIRE_MINUTES", "10080")
    monkeypatch.setenv("CORS_ALLOWED_ORIGINS", '["*"]')
    monkeypatch.setenv("SYNC_PULL_DEFAULT_LIMIT", "100")
    monkeypatch.setenv("SYNC_PULL_MAX_LIMIT", "500")
    monkeypatch.setenv("AUTH_RATE_LIMIT_MAX_REQUESTS", "30")
    monkeypatch.setenv("AUTH_RATE_LIMIT_WINDOW_SECONDS", "60")
    monkeypatch.setenv("DEFAULT_BUSINESS_TIMEZONE", "Asia/Kathmandu")
    monkeypatch.setenv("DEFAULT_CALENDAR_MODE", "BS")

    settings = Settings(_env_file=None)

    assert settings.effective_database_url == "postgresql+psycopg2://override"
    assert settings.enable_api_docs is False


def test_missing_required_db_settings_fail_fast(monkeypatch) -> None:
    monkeypatch.setenv("APP_NAME", "Naphaa API")
    monkeypatch.setenv("API_V1_PREFIX", "/api/v1")
    monkeypatch.setenv("APP_PORT", "8000")
    monkeypatch.setenv("DEBUG", "true")
    monkeypatch.setenv("ENABLE_API_DOCS", "false")
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("DB_HOST", raising=False)
    monkeypatch.delenv("DB_PORT", raising=False)
    monkeypatch.delenv("DB_NAME", raising=False)
    monkeypatch.delenv("DB_USER", raising=False)
    monkeypatch.delenv("DB_PASSWORD", raising=False)
    monkeypatch.delenv("DB_SSLMODE", raising=False)
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("REFRESH_TOKEN_EXPIRE_MINUTES", "10080")
    monkeypatch.setenv("CORS_ALLOWED_ORIGINS", '["*"]')
    monkeypatch.setenv("SYNC_PULL_DEFAULT_LIMIT", "100")
    monkeypatch.setenv("SYNC_PULL_MAX_LIMIT", "500")
    monkeypatch.setenv("AUTH_RATE_LIMIT_MAX_REQUESTS", "30")
    monkeypatch.setenv("AUTH_RATE_LIMIT_WINDOW_SECONDS", "60")
    monkeypatch.setenv("DEFAULT_BUSINESS_TIMEZONE", "Asia/Kathmandu")
    monkeypatch.setenv("DEFAULT_CALENDAR_MODE", "BS")

    try:
        Settings(_env_file=None)
        raised = False
    except ValidationError:
        raised = True

    assert raised is True


def test_enable_api_docs_defaults_to_false(monkeypatch) -> None:
    monkeypatch.setenv("APP_NAME", "Naphaa API")
    monkeypatch.setenv("API_V1_PREFIX", "/api/v1")
    monkeypatch.setenv("APP_PORT", "8000")
    monkeypatch.setenv("DEBUG", "false")
    monkeypatch.delenv("ENABLE_API_DOCS", raising=False)
    monkeypatch.setenv("DB_HOST", "example.postgres.database.azure.com")
    monkeypatch.setenv("DB_PORT", "5432")
    monkeypatch.setenv("DB_NAME", "naphaa-database")
    monkeypatch.setenv("DB_USER", "naphaa-user")
    monkeypatch.setenv("DB_PASSWORD", "secret")
    monkeypatch.setenv("DB_SSLMODE", "require")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("REFRESH_TOKEN_EXPIRE_MINUTES", "10080")
    monkeypatch.setenv("CORS_ALLOWED_ORIGINS", '["*"]')
    monkeypatch.setenv("SYNC_PULL_DEFAULT_LIMIT", "100")
    monkeypatch.setenv("SYNC_PULL_MAX_LIMIT", "500")
    monkeypatch.setenv("AUTH_RATE_LIMIT_MAX_REQUESTS", "30")
    monkeypatch.setenv("AUTH_RATE_LIMIT_WINDOW_SECONDS", "60")
    monkeypatch.setenv("DEFAULT_BUSINESS_TIMEZONE", "Asia/Kathmandu")
    monkeypatch.setenv("DEFAULT_CALENDAR_MODE", "BS")

    settings = Settings(_env_file=None)

    assert settings.enable_api_docs is False
