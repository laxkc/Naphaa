# SME Digital (Byapari)

Offline-first SME sales, inventory, credit, and expense management app for small shops.

## What is this?

SME Digital is a mobile-first business operations system for retail shops (especially shops with unstable internet). It includes a Flutter mobile app and a FastAPI backend with offline sync.

## Who is it for?

- Small retail shop owners (kirana / convenience stores)
- Shop staff doing daily sales and stock entry
- SMEs that need credit tracking, expense tracking, and simple business insights

## What problem does it solve?

Many shops lose trust in software when internet drops. This app solves that by:

- working offline first (save locally)
- syncing automatically when internet returns
- keeping backend as the global source of truth
- giving actionable insights (credit risk, stock health, business health)

## How does it work?

1. Mobile app saves sales/customers/expenses/products to local SQLite first.
2. Each local change is added to an outbox (`sync_queue`).
3. Sync engine pushes pending changes to backend (`/sync/push`), then pulls updates (`/sync/pull` + metrics endpoints).
4. Backend validates, applies, and stores canonical data.
5. Mobile refreshes local caches and UI from synced data.

## Tech stack?

- Mobile: Flutter (Dart), Riverpod, `sqflite`, Dio
- Backend: FastAPI (Python), SQLAlchemy, Pydantic, `uv`, Uvicorn
- Sync: custom offline-first outbox + cursor-based pull + ACKed push
- Infra (starter): `infra/` folder (Docker/Nginx/Postgres placeholders/scripts)

## Core features?

- Auth (login/signup, refresh, logout)
- Products + stock adjustment + low-stock threshold
- Sales (cash + credit)
- Customers + credit balance + record payment
- Expenses
- Reports (sales, profit, credit, ledger)
- Business Health dashboard (profit snapshot, credit risk, stock health, alerts)
- Credit Aging report + customer risk score (green/yellow/red)
- Product Insights (profit by product, dead stock, fast movers)
- Alerts feed (credit overdue, expense spike, dead stock/stock risk signals)
- Offline-first sync with diagnostics + retry/backoff

## How to run locally?

### 1) Backend

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/backend
uv sync
uv run uvicorn app.main:app --reload
```

Backend URLs:

- API: `http://127.0.0.1:8000/api/v1`
- Swagger: `http://127.0.0.1:8000/docs`
- Health: `http://127.0.0.1:8000/health`

### 2) Mobile (Flutter)

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/mobile
flutter pub get
flutter run --dart-define=APP_ENV=dev
```

Notes:

- API base URL comes from `/Users/laxmankc/Startup/SME/sme-digital/mobile/assets/env/dev.json` or `prod.json`
- environment selector is `--dart-define=APP_ENV=dev|prod`
- for custom files, use `--dart-define=APP_ENV_ASSET=assets/env/<name>.json`

### 3) Tests (optional)

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/backend
uv run pytest
```

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/mobile
flutter test
flutter analyze
```

## How to deploy?

Current repo includes an `infra/` folder, but deployment scripts are placeholder-level right now.

Baseline deployment (manual)

1. Deploy backend (FastAPI/Uvicorn) on a server
2. Use PostgreSQL in production
3. Put Nginx/reverse proxy in front of backend
4. Point mobile app API base URL to production backend
5. Run DB backups (see `/Users/laxmankc/Startup/SME/sme-digital/infra/scripts/backup.sh` placeholder)


- Manual release QA checklist runs (unstable network scenarios)
- Full E2E test automation (device/network chaos)
- Feature flags for intelligence/risk rollout (optional)
- Stronger RBAC enforcement (beyond current foundation)
- Local DB encryption rollout (SQLCipher path)

## Project docs

- Progress tracker: `/Users/laxmankc/Startup/SME/sme-digital/PROGRESS.md`
- Docs index: `/Users/laxmankc/Startup/SME/sme-digital/docs/README.md`
