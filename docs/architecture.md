# SME Digital - System Architecture

Status date: February 19, 2026

## 1. Overview

SME Digital is a mobile-first, offline-capable bookkeeping and inventory platform for small retail shops.

Architecture goals:

- Offline-first reliability
- Fast daily operations on Android + iOS
- Strong stock and credit integrity
- Monolithic backend for rapid iteration
- Clear path to scale

## 2. High-Level Architecture

Flutter Mobile App (Android/iOS)
-> Local SQLite + Sync Queue
-> FastAPI REST API (`/api/v1`)
-> SQL database (SQLite local/dev, PostgreSQL-compatible schema)
-> Backup and monitoring stack

## 3. Mobile Architecture

Pattern: feature-first modular architecture.

Primary runtime components:

- Local database cache (products, customers, sales, payments, refunds, stock movements, expenses)
- API client layer
- Auth token storage
- Sync manager + retry queue
- State management (loading/success/failure states)

Write strategy:

- User action writes locally first.
- Sync queue pushes in background.
- UI remains usable during network loss.

## 4. Backend Architecture

Monolithic FastAPI service with layered structure:

- `api/` route handlers
- `services/` business rules + transaction orchestration
- `models/` SQLAlchemy entities
- `schemas/` request/response validation
- `core/` config, security, DB, logging, rate limit

Core domains:

- Auth + store
- Products + stock movements
- Customers + payments + ledger
- Sales + sale payments + refunds
- Expenses + reports
- Devices + sync events
- Export

## 5. Auth & Security Flow

Implemented security behaviors:

- JWT access + refresh tokens
- Auth rate limiting on login/register
- Refresh token revocation list (`revoked_tokens`)
- `POST /auth/logout` hashes and revokes refresh token
- `POST /auth/change-password` with current-password verification
- Structured error codes (`detail.code`, `detail.detail`)

## 6. Sales & Inventory Transaction Boundaries

Sale creation is transactional:

1. Validate sale payload and payment split totals.
2. Deduct stock for each sale item.
3. Create sale + sale items + sale payment rows.
4. Update customer balance for credit component.
5. Write stock movement audit rows.
6. Commit or rollback as one unit.

Refund creation is transactional:

1. Validate refundable quantity.
2. Create refund + refund item rows.
3. Restore stock and write stock movement entries.
4. Reduce sale total and adjust customer credit impact.
5. Commit or rollback as one unit.

## 7. Sync Architecture

### Push/Pull model

- Client sends queued changes via `POST /sync/push`.
- Server stores sync events with dedup fingerprint.
- Client fetches changes via `GET /sync/pull`.

### Dedup behavior

- Unique key: `(store_id, fingerprint)` on sync events.
- Duplicate pushes are ignored safely.

### Sync observability

- `GET /sync/status` returns:
  - server time
  - last event id
  - recommended pull timestamp

## 8. Data Integrity Rules

Implemented guards:

- Stock cannot go negative.
- Credit sales require customer linkage.
- Customer payment cannot exceed outstanding balance.
- Product deletion is soft-delete and blocked if linked sales exist.
- Customer deletion is soft-delete and blocked when balance > 0.
- Sales idempotency key prevents duplicate transaction creation.

## 9. Deployment Model (Current)

Single-service deployment suitable for MVP/pilot:

- FastAPI app
- SQL database
- Reverse proxy
- Periodic backups

Scaling path:

- Managed DB migration
- Worker queue for heavy jobs
- API horizontal scaling
- Optional cache layer
