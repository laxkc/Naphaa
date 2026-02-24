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

API will be available at:

- `http://127.0.0.1:8000`
- Docs: `http://127.0.0.1:8000/docs`
- Health check: `http://127.0.0.1:8000/health`

## Environment (optional)

Create `backend/.env` to override defaults, for example:

```env
DATABASE_URL=sqlite:///./sme_digital.db
JWT_SECRET_KEY=change-me
DEBUG=true
```

## Tests

```bash
cd backend
uv run pytest
```
