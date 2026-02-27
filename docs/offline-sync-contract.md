# Offline Sync Contract (v1)

Last updated: 2026-02-27

Status: `Frozen for Starter Production Scope (S0-S2)`

## Source of Truth

- Backend DB = global source of truth
- Mobile SQLite = offline cache + pending-write outbox
- UI reads local DB (fast/offline)
- Sync updates local DB from backend changes

## Sync Flow

1. Local write first (mobile)
2. Queue outbox event (`sync_queue`)
3. Push queued events (`/sync/push`) in chunks
4. Pull server events (`/sync/pull`) with cursor pagination
5. Apply pulled events to local DB
6. Refresh local-first providers/UI

Contract order is strict: `push -> pull`.

## Event Envelope

Used by `/sync/push`:

- `op_id`: unique operation ID (UUID)
- `device_id`: stable device ID (UUID, persisted on device)
- `entity`: `product | customer | customer_payment | expense | sale`
- `operation`: `UPSERT | DELETE | ADJUST_STOCK`
- `payload`: entity payload

## Payload Rules

- All payloads include `schema_version`
- Current version: `1`
- Unknown payload fields must be ignored by consumers (forward compatibility)

## Entity Payload Baseline (v1)

### Product (`UPSERT`)
- `schema_version`
- `id`
- `name`
- `sell_price`
- `cost_price`
- `stock_qty`
- `low_stock_threshold`
- `is_active`
- `updated_at`
- optional `device_id`

### Product (`DELETE`)
- `schema_version`
- `id`
- `is_deleted=true`
- `deleted_at`
- `updated_at` (optional)
- optional `device_id`

### Product (`ADJUST_STOCK`)
- `schema_version`
- `id`
- `delta_qty`
- `reason`
- `updated_at`
- optional `device_id`

### Customer (`UPSERT`)
- `schema_version`
- `id`
- `name`
- `phone`
- `balance`
- `updated_at`
- `is_deleted` (optional)
- optional `device_id`

### Customer (`DELETE`)
- `schema_version`
- `id`
- `is_deleted=true`
- `deleted_at`
- `updated_at` (optional)
- optional `device_id`

### Customer Payment (`UPSERT`)
- `schema_version`
- `id`
- `customer_id`
- `method`
- `amount`
- `note`
- `created_at`
- optional `device_id`

### Expense (`UPSERT`)
- `schema_version`
- `id`
- `category`
- `amount`
- `note`
- `created_at`
- optional `device_id`

### Expense (`DELETE`)
- `schema_version`
- `id`
- `deleted_at`
- optional `device_id`

### Sale (`UPSERT`)
- `schema_version`
- `id`
- `sale_type`
- `payment_method`
- `customer_id` (optional)
- `total_amount`
- `created_at`
- `items[]` (`product_id`, `qty`, `unit_price`)
- `payments[]` (`id?`, `method`, `amount`, `created_at?`)
- optional `device_id`

## Protocol Reliability Features (Implemented)

- Cursor-based pull (`next_cursor`)
- Push ACKs by `op_id`
- Chunked push/pull
- Idempotency semantics using `device_id + op_id` (backend fallback to legacy fingerprint)
- Conflict policy: backend authoritative, LWW merge on pull apply
- Retry policy (mobile outbox): exponential backoff with `next_retry_at`, max 5 retries, then `blocked`
