# Backend

FastAPI backend for the SME Digital platform.

## Requirements

- Python 3.12+
- `uv`

## Setup

```bash
cd backend
uv sync
```

## Run locally

```bash
cd backend
uv run uvicorn app.main:app --reload
```

## Run on Azure App Service

Use this startup command if the whole repo is deployed and the backend lives in
the `backend/` folder:

```bash
bash backend/startup.sh
```

On local macOS, the script also sets
`OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` to avoid Gunicorn worker crashes
during prefork startup.

Equivalent direct command:

```bash
APP_PORT=8080 gunicorn --bind 0.0.0.0:${PORT:-8080} --timeout 600 -k uvicorn.workers.UvicornWorker --chdir backend app.main:app
```

API will be available at:

- `http://127.0.0.1:8000`
- Docs: `http://127.0.0.1:8000/docs`
- Health check: `http://127.0.0.1:8000/health`

## Environment (optional)

The backend now defaults to PostgreSQL. It loads `.env` first and
falls back to `.env.development`. Database connection settings and
`JWT_SECRET_KEY` are expected from env, not hardcoded in Python.

Current development database:

```env
APP_NAME=SME Digitization API
API_V1_PREFIX=/api/v1
DEBUG=true
DB_HOST=naphaa-server.postgres.database.azure.com
DB_PORT=5432
DB_NAME=naphaa-database
DB_USER=nvaecgrwtz
DB_PASSWORD=your_password
DB_SSLMODE=require
JWT_SECRET_KEY=change-me-development
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_MINUTES=10080
CORS_ALLOWED_ORIGINS=["*"]
SYNC_PULL_DEFAULT_LIMIT=100
SYNC_PULL_MAX_LIMIT=500
AUTH_RATE_LIMIT_MAX_REQUESTS=30
AUTH_RATE_LIMIT_WINDOW_SECONDS=60
DEFAULT_BUSINESS_TIMEZONE=Asia/Kathmandu
DEFAULT_CALENDAR_MODE=BS
```

If needed, create `backend/.env` to override development values:

```env
APP_NAME=SME Digitization API
API_V1_PREFIX=/api/v1
DEBUG=true
DB_HOST=naphaa-server.postgres.database.azure.com
DB_PORT=5432
DB_NAME=naphaa-database
DB_USER=nvaecgrwtz
DB_PASSWORD=your_password
DB_SSLMODE=require
JWT_SECRET_KEY=change-me
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_MINUTES=10080
CORS_ALLOWED_ORIGINS=["*"]
SYNC_PULL_DEFAULT_LIMIT=100
SYNC_PULL_MAX_LIMIT=500
AUTH_RATE_LIMIT_MAX_REQUESTS=30
AUTH_RATE_LIMIT_WINDOW_SECONDS=60
DEFAULT_BUSINESS_TIMEZONE=Asia/Kathmandu
DEFAULT_CALENDAR_MODE=BS
```

## Tests

```bash
cd backend
uv run pytest
```

## Migrations

This backend now uses Alembic for schema management.

For an existing database that already matches the current models, stamp the
baseline revision once:

```bash
cd backend
uv run alembic stamp 20260228_120000
```

For future schema changes:

```bash
cd backend
uv run alembic revision --autogenerate -m "describe_change"
uv run alembic upgrade head
```

Useful commands:

```bash
uv run alembic current
uv run alembic history
uv run alembic upgrade head
```
