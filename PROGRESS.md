# SME Digital Progress (Offline-First Refactor)

Last updated: 2026-02-23

## Goal

Make the app reliable in Nepal's unstable internet conditions:

- Works fully offline
- Saves data locally first
- Syncs automatically when internet returns
- Backend remains global source of truth
- Mobile local DB remains offline cache/runtime store

## Current Architecture (Reviewed)

### Mobile (already exists)

- Local DB: `sqflite` (`/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/core/storage/local_db.dart`)
- Local-first writes with sync queue:
  - products, sales, customers, expenses create local rows first
  - writes add events into `sync_queue`
- Batch sync service:
  - push pending queue
  - pull events from backend
  - apply pulled events to local DB

### Backend (already exists)

- `/api/v1/sync/push`
- `/api/v1/sync/pull`
- `/api/v1/sync/status`
- `sync_events` table + dedupe fingerprint

## What Is Working

- Offline local data entry foundation exists (products/sales/customers/expenses)
- Push/pull sync endpoints exist
- Connectivity check exists before sync
- Mobile initial pull bug was fixed (fresh client now does full pull)
- Product low-stock threshold sync support was added (mobile + backend projection)

## Key Gaps Found (Needs Refactor)

### P0 (Critical)

- No automatic sync on internet reconnect (`onConnectivityChanged` listener not wired)
- Pull cursor uses local wall-clock (`lastSyncAt = now`) instead of server cursor/watermark
- `sync_queue` is too basic (`synced` boolean only; no retry/error metadata)
- Local IDs use timestamp-based strings, not UUIDs
- Backend `/sync/push` projects only `product` events fully; other entities are incomplete
- Backend normal APIs (`/products`, `/sales`, `/expenses`, etc.) do not consistently emit `sync_events`
- Local DB schema drift exists (customer repo uses columns not present in local schema/migrations)

### P1 (Important)

- Sync orchestration is scattered across screens/controllers
- UI sync state is not centralized (offline/syncing/pending indicators)
- Conflict handling policy is not codified in code/contracts
- Reports/dashboard mix local and remote behavior inconsistently in some flows

## Refactor Plan (Staged)

## Phase Tracker

- [x] Phase 0: Contracts and Rules (P0)
- [x] Phase 1: Mobile Data Layer Hardening (P0)
- [x] Phase 2: Mobile Sync Coordinator (P0)
- [x] Phase 3: Sync Protocol Improvements (P0/P1)
- [x] Phase 4: Backend Sync Backbone (P0)
- [x] Phase 5: Merge/Conflict Rules (P1)
- [x] Phase 6: UX Transparency (P1)
- [x] Phase 7: Reports/Dashboard Consistency (P1)
- [x] Phase 8: Tests and Rollout (P0/P1) (checklist + smoke validation baseline complete; full automated suites still future hardening)

## Phase 0: Contracts and Rules (P0)

- [x] Define sync payload contract per entity (`product`, `sale`, `expense`, `customer`, payments)
- [x] Add `schema_version` to sync payloads
- [x] Keep single-device-per-store conflict policy for now (documented policy)
- [x] Document source-of-truth rules (backend global, mobile local cache)

## Phase 1: Mobile Data Layer Hardening (P0)

- [x] Fix local schema drift (customers columns, soft-delete fields, metadata columns)
- [x] Upgrade `sync_queue` into a proper outbox table:
  - `op_id`, `entity_id`, `status`, `retry_count`, `last_error`, timestamps
- [x] Replace timestamp ID generation with UUIDs across repos

## Phase 2: Mobile Sync Coordinator (P0)

- [x] Add one sync coordinator service
- [x] Trigger sync on:
  - app startup
  - internet reconnect
  - periodic foreground interval
- [x] Add debounce, retry backoff, and concurrency lock
- [x] Expose sync status provider (`offline`, `syncing`, `pending`, `last_success`, `last_error`)

## Phase 3: Sync Protocol Improvements (P0/P1)

- [x] Replace time-based pull with server cursor (`next_cursor`) (with `since` fallback for compatibility)
- [x] Push response should ack events individually by `op_id`
- [x] Chunk push/pull batches for unstable connections
- [x] Add idempotency key (`device_id + op_id`) semantics

## Phase 4: Backend Sync Backbone (P0)

- [x] Emit `sync_events` for normal API writes (products, expenses, customers, customer payments, sales create)
- [x] Extend `/sync/push` projector to apply (core entities + core delete/tombstone ops):
  - `sale`
  - `expense`
  - `customer`
  - `customer_payment`
  - delete/tombstone operations
- [x] Keep projection + sync event append in one DB transaction

## Phase 5: Merge/Conflict Rules (P1)

- [x] Single-device mode first (recommended) (documented policy)
- [x] Add explicit merge rules for later multi-device support (documented roadmap/rules)
- [x] Add tombstone sync (`is_deleted`, `deleted_at`) (core customer/product/expense flows)

## Phase 6: UX Transparency (P1)

- [x] Offline indicator
- [x] Syncing indicator
- [x] Pending changes count
- [x] Sync error banner + retry action

## Phase 7: Reports/Dashboard Consistency (P1)

- [x] Local DB drives UI
- [x] Sync updates local DB
- [x] UI refreshes from local providers after sync
- [x] Avoid mismatched local-vs-remote totals unless explicitly labeled

## Phase 8: Tests and Rollout (P0/P1)

- [x] Mobile static analysis smoke check (`flutter analyze`)
- [x] Backend import/startup smoke check (`import app.main`)
- [x] Manual E2E + rollout checklist documented
- [ ] Automated migration/repository/sync integration tests (future hardening)
- [ ] Full E2E test automation (future hardening)

## Suggested Execution Order (Practical)

1. Fix local schema drift + UUIDs + outbox schema
2. Backend event emission for normal API writes
3. Backend projector for all entities in `/sync/push`
4. Cursor-based `/sync/pull`
5. Mobile sync coordinator with reconnect listener + backoff
6. UI sync status indicators
7. Cleanup ad-hoc sync calls in feature screens/controllers

## Immediate Next Tasks (Recommended)

- [x] Audit and patch local customer schema mismatch (`address`, `notes`, `is_deleted`)
- [x] Introduce UUID helper and replace timestamp IDs in repositories
- [x] Expand `sync_queue` schema with `op_id/status/retry_count/last_error`
- [x] Add backend sync event emitter helper for product/sale/expense/customer writes
- [x] Add connectivity listener-based auto sync coordinator
- [x] Add explicit tombstone sync for customer/product deletes (backend emit + backend/mobile apply)
- [x] Add expense delete endpoint + tombstone sync (if required by product scope)

## Testing Plan (Hardening)

### Backend Sync Protocol Tests (`pytest`)

- [x] `/sync/push` ACK contract assertions (`acked_op_ids` contents, not just status)
- [x] `device_id + op_id` idempotency tests (duplicate replay)
- [x] legacy fingerprint fallback idempotency tests
- [x] `/sync/pull` cursor + `limit` pagination tests (`next_cursor`, multi-page flow)
- [x] `since` fallback compatibility tests for old clients

### Backend Sync Projector Tests (`pytest`)

- [x] `product` projector tests (`UPSERT`, `DELETE`, `ADJUST_STOCK`)
- [x] `customer` projector tests (`UPSERT`, `DELETE`)
- [x] `customer_payment` projector tests (payment row + customer balance update)
- [x] `expense` projector tests (`UPSERT`, `DELETE`)
- [x] `sale` projector tests (sale/items/payments + stock deduction + credit balance)
- [x] duplicate sale replay safety (no double stock/customer updates)

### Backend API -> Sync Event Emission Tests (`pytest`)

- [x] product create/update/delete/adjust-stock emit sync events
- [x] customer create/update/delete/payment emit sync events
- [x] expense create/delete emit sync events
- [x] sale create emits sync event
- [x] emitted payloads include `schema_version`

### Mobile Local DB Migration Tests (`flutter test`)

- [x] migration `v5 -> v6` (customer columns: `address`, `notes`, `created_at`, `is_deleted`)
- [x] migration `v6 -> v7` (outbox columns + backfill `status/updated_at`)

### Mobile SyncService Tests (`flutter test`)

- [x] outbox state transitions (`pending -> syncing -> synced`)
- [x] non-ACK handling (`failed` + retry count increment)
- [x] push chunking (> chunk size)
- [x] pull cursor pagination applies all pages
- [x] `DELETE` apply for `product/customer/expense` (product covered; customer/expense dedicated tests can be added)
- [x] cursor persistence (`last_sync_cursor`)
- [x] legacy `lastSyncAt` fallback when no cursor exists

### Mobile Sync Coordinator Tests (`flutter test`)

- [x] reconnect trigger (debounced)
- [x] periodic sync trigger
- [x] in-flight lock behavior
- [x] retry backoff delays and reset-on-success (backoff delay/skip covered; explicit reset-on-success follow-up can be added)
- [x] provider invalidation after successful sync

### Dashboard / Report Consistency Tests (`flutter test`)

- [x] dashboard summary local-first totals from local DB
- [x] dashboard/report values refresh after sync-triggered invalidation
- [x] sales/profit period filters remain correct with synced timestamps

### Manual E2E QA (Device/Simulator + Backend)

- [ ] offline create product/customer/expense/sale -> reconnect -> backend reflects all
- [ ] delete sync propagation (product/customer/expense)
- [ ] token expiry during sync refreshes and resumes
- [ ] unstable network toggling does not create duplicate rows
- [ ] low stock threshold stays consistent across mobile/backend sync

### CI / Execution Order

- [x] backend `uv run pytest`
- [x] mobile `flutter analyze`
- [x] mobile `flutter test`
- [ ] periodic manual checklist run (`docs/offline-rollout-checklist.md`)

## Non-Match Refactor Plan (Production Readiness)

Purpose: close remaining gaps against SME transaction/offline/sync principles after the core offline-first refactor.

### Priority P0 (Financial/Data Integrity)

- [x] `sync/push` ACK semantics refactor (backend)
  - [x] Per-event `failed_events` response contract added
  - [x] ACK only on applied or idempotent duplicate events (not pre-ACKed)
  - [ ] Per-event duplicate/applied status classification (optional refinement)
  - [x] Full-suite regression pass after contract change
  - Goal: ACK only successfully validated/applied events; return explicit per-event failures
  - Current gap: backend can ACK `op_id` before/without meaningful apply (`app/services/sync_service.py`)
  - Implementation plan:
    - return `acked_op_ids` only for applied/deduped-valid events
    - add `failed_events: [{op_id, entity, operation, code, message}]`
    - differentiate `duplicate` vs `invalid` vs `apply_failed`
    - keep backward compatibility for mobile (treat missing `failed_events` as legacy)
  - Test plan:
    - invalid payload is not ACKed
    - unknown entity/op is not ACKed
    - duplicate is ACKed (idempotent) with duplicate status

- [x] Sync sale projector atomicity hardening (backend)
  - Goal: no partial sale projection (`sale`, `items`, `payments`, stock, customer credit)
  - Current gap: projector may skip invalid items and still insert sale/payments/credit
  - Implementation plan:
    - pre-validate entire payload (all referenced products exist, all qty valid, stock sufficient)
    - fail whole event if any item invalid/insufficient
    - verify `items` total matches `total_amount` (or derive and compare)
    - verify payment totals and credit component consistency
  - Test plan:
    - missing product -> no sale row, no payment row, no stock change
    - insufficient stock -> no sale row, no credit change
    - bad payment totals -> reject event

- [x] Atomic stock deduction/update SQL (backend)
  - Goal: eliminate race-prone read-modify-write for critical inventory writes
  - Current gap: `InventoryService.deduct_stock()` updates ORM object in memory
  - Implementation plan:
    - use SQL update with guard (`WHERE stock_qty >= :qty`)
    - check affected row count; raise `INSUFFICIENT_STOCK` on `0 rows`
    - apply same pattern in sync `ADJUST_STOCK` / sale projector paths where needed
  - Test plan:
    - simulated concurrent deductions do not oversell
    - stock never goes below zero

### Priority P1 (Sync Correctness / Conflict Handling)

- [ ] Explicit server-wins conflict semantics (backend + mobile)
  - Goal: deterministic conflict resolution beyond single-device assumption
  - Current gap: no version/timestamp conflict checks in projector UPSERTs
  - Implementation plan:
    - add entity-level `server_updated_at` / `sync_version` checks on mutable master data (`product`, `customer`)
    - define reject/overwrite policy per entity type
    - return conflict errors in `sync/push` failure payload
    - mobile marks rows `failed` with conflict code and surfaces retry/manual resolution
  - Test plan:
    - stale UPSERT rejected/overwritten per policy
    - duplicate replay still idempotent

- [ ] Mobile partial-sync status semantics
  - [x] Mobile `SyncService` stores backend `failed_events` reason in outbox `last_error`
  - [ ] `SyncService.processPendingSync()` structured result counts (`acked/failed/pulled`)
  - [ ] `SyncCoordinatorController` warning state for partial success
  - Goal: UI should not show clean success if outbox rows failed
  - Current gap: coordinator can set `lastSuccessAt` after partial failure in `SyncService`
  - Implementation plan:
    - `SyncService.processPendingSync()` returns structured result (`pushed`, `acked`, `failed`, `pulled`)
    - `SyncCoordinatorController` sets warning/error state when `failed > 0`
    - keep `lastSuccessAt` semantics for fully-successful sync only (or split into `lastRunAt` / `lastSuccessAt`)
  - Test plan:
    - partial ACK updates warning banner
    - full success clears error and resets backoff

- [ ] Sync projector strict unknown-operation/entity handling (backend)
  - Goal: no silent no-op acceptance
  - Current gap: `_apply_event()` silently returns on unsupported entity/op
  - Implementation plan:
    - raise typed validation error for unsupported entity/op in `sync/push`
    - include failure entry in response
  - Test plan:
    - unsupported entity rejected and not ACKed

### Priority P2 (Financial Auditability / Domain Hardening)

- [ ] Unified `ledger_entries` table (backend)
  - Goal: immutable financial audit trail for sales/expenses/payments/refunds
  - Current gap: data spread across multiple tables, no single ledger stream
  - Implementation plan:
    - add `ledger_entries` schema (`store_id`, `entity_type`, `entity_id`, `entry_type`, `amount`, `direction`, `created_at`, metadata JSON)
    - write entries from sale/payment/expense/refund flows
    - expose ledger export/report endpoints later
  - Test plan:
    - every financial write creates exactly one or more expected ledger entries

- [ ] Soft-delete strategy alignment (backend + mobile cache)
  - Goal: preserve history consistently while allowing local cache pruning
  - Current gap: mobile applies some `DELETE` events as hard delete in local cache
  - Implementation plan:
    - decide per-entity cache policy (`soft delete locally` vs `hard-delete cache only`)
    - document and standardize mobile apply behavior
    - prefer local tombstones for entities with UI/history needs
  - Test plan:
    - deleted product/customer remains hidden but audit/history remains queryable where expected

### Priority P3 (Security / Ops)

- [ ] Refresh token rotation (backend)
  - Goal: rotate and revoke prior refresh token on `/auth/refresh`
  - Current gap: refresh issues new token pair without revoking old refresh token
  - Implementation plan:
    - revoke submitted refresh token on successful refresh
    - optionally persist token family/session id for stricter replay detection
  - Test plan:
    - old refresh token rejected after refresh
    - logout revokes active refresh token as before

- [ ] Local DB encryption assessment and implementation plan (mobile)
  - Goal: at-rest protection for sensitive local data
  - Current gap: plain `sqflite` database
  - Implementation plan:
    - evaluate `sqlcipher`/encrypted SQLite support for Flutter target platforms
    - migration/backward compatibility plan for existing installs
    - key storage strategy (Keychain/Keystore via secure storage)
  - Deliverable:
    - RFC/decision doc + implementation spike before rollout

- [ ] RBAC foundation (backend)
  - Goal: role-based access control for multi-user/store operations
  - Current gap: no roles/permissions model
  - Implementation plan:
    - add roles (`owner`, `staff`, optional `viewer`)
    - enforce permission checks in sensitive endpoints (products, sales refunds, settings, exports)
    - include role claims/profile endpoint support
  - Test plan:
    - endpoint authorization matrix tests by role

### Priority P4 (Performance / Observability)

- [ ] Sync chunk size tuning and config
  - Goal: adapt chunk sizes for unstable internet (`20-50` recommended baseline)
  - Current state: push `100`, pull `200`
  - Implementation plan:
    - move chunk sizes to config
    - reduce defaults (e.g. push `50`, pull `100`) and measure
    - optional dynamic chunk backoff on timeout/failure

- [ ] Sync telemetry / diagnostics (backend + mobile)
  - Goal: production debugging without guessing
  - Implementation plan:
    - backend structured logs for sync runs (`store_id`, pushed, applied, duplicates, failed)
    - mobile sync run summary (`pending`, `acked`, `failed`, `pulled`, duration`)
    - optional debug screen for outbox diagnostics in dev/admin mode
  - Test plan:
    - unit tests for result aggregation and error propagation

## Non-Match Implementation Order (Recommended)

1. `P0-1` ACK semantics + per-event failures (`sync/push`)
2. `P0-2` sync sale projector strict atomic validation/apply
3. `P0-3` atomic stock SQL update in normal API + projector paths
4. `P1-1` mobile partial-sync result handling + UI warning state
5. `P1-2` unsupported entity/op hard failures
6. `P3-1` refresh token rotation
7. `P4-1` telemetry + chunk tuning
8. `P2-1` ledger entries
9. `P3-2` local DB encryption
10. `P3-3` RBAC foundation

## Non-Match Tracking (Next Actionable Slice)

- [x] Implement `sync/push` per-event apply result contract (ACK only applied/deduped-valid)
- [x] Update mobile `SyncService` to consume `failed_events` and preserve failed rows with clear reasons
- [x] Add tests for invalid sync events (not ACKed) and duplicate events (ACKed idempotently)
- [x] Add backend/mobile full regression run and record results for this slice

## Notes

- Current app is already partially offline-first (good base).
- Refactor focus is reliability and completeness, not rewriting everything.
- Keep mobile local-first UX; sync should refresh local DB and then UI.
- Sync contract docs: `docs/offline-sync-contract.md`
- Conflict policy docs: `docs/offline-conflict-policy.md`
- Rollout/test checklist: `docs/offline-rollout-checklist.md`
- Automated test status (2026-02-24):
  - Backend `uv run pytest` -> `56 passed`
  - Mobile `flutter test` -> `All tests passed`
  - Mobile `flutter analyze` -> `No issues found!`
- Hardening tests added and passing (2026-02-23):
  - Backend `tests/api/test_sync.py` (protocol + projector coverage incl. ACK/idempotency/cursor+limit, ADJUST_STOCK, and duplicate sale replay safety) -> `15 passed`
  - Backend `tests/api/test_products_customers_sales_expenses_reports.py` (API -> sync-event emission assertions incl. exact create/delete operations + schema_version) -> `23 passed`
  - Mobile `test/integration/local_db_migration_test.dart` (`v5->v6`, `v6->v7`) -> `All tests passed`
  - Mobile `test/integration/sync_service_test.dart` (ACK reconciliation, chunking, delete apply, cursor pagination/persistence, legacy `lastSyncAt` fallback) -> `All tests passed`
  - Mobile `test/integration/sync_coordinator_test.dart` (reconnect debounce, periodic trigger, in-flight lock, retry backoff skip, provider invalidation) -> `All tests passed`
  - Mobile `test/integration/dashboard_report_consistency_test.dart` (dashboard local-first totals, sales/profit-style synced-timezone period filtering, sync-triggered dashboard/report refresh) -> `All tests passed`
  - Test harness hardening: backend `tests/conftest.py` resets in-memory auth rate limiter between tests to avoid flaky `429` failures in full-suite runs
  - Sync push contract hardening (2026-02-24):
    - Backend `/sync/push` now returns `failed_events` and ACKs only applied/idempotent-valid events
    - Mobile `SyncService` persists backend failure reason into outbox `last_error`
    - Backend `tests/api/test_sync.py` -> `18 passed`
    - Mobile `test/integration/sync_service_test.dart` -> `All tests passed`
    - Mobile `flutter analyze` -> `No issues found!`
  - P0 financial integrity hardening (2026-02-24):
    - Sync sale projector now validates all items/payments/customer requirements before insert/apply (no partial sale projection)
    - Backend inventory deduction and stock adjustment now use atomic guarded SQL updates
    - Sync coordinator lifecycle hardened with `ref.mounted` guards (fixed full-suite dispose race)
    - Backend `uv run pytest` -> `56 passed`
    - Mobile `flutter test` -> `All tests passed`
    - Mobile `flutter analyze` -> `No issues found!`
