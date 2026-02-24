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

- [x] Explicit server-wins conflict semantics (backend + mobile)
  - Goal: deterministic conflict resolution beyond single-device assumption
  - Implemented:
    - backend sync projector rejects stale `product`/`customer` UPSERTs using `updated_at` timestamp checks (`CONFLICT_STALE_EVENT`)
    - conflict failures returned in `/sync/push` `failed_events`
    - mobile outbox persists failure codes/messages via `last_error`
  - Implementation plan:
    - add entity-level `server_updated_at` / `sync_version` checks on mutable master data (`product`, `customer`)
    - define reject/overwrite policy per entity type
    - return conflict errors in `sync/push` failure payload
    - mobile marks rows `failed` with conflict code and surfaces retry/manual resolution
  - Test plan:
    - stale UPSERT rejected/overwritten per policy
    - duplicate replay still idempotent

- [x] Mobile partial-sync status semantics
  - [x] Mobile `SyncService` stores backend `failed_events` reason in outbox `last_error`
  - [x] `SyncService.processPendingSync()` structured result counts (`acked/failed/pulled`)
  - [x] `SyncCoordinatorController` warning state for partial success
  - Goal: UI should not show clean success if outbox rows failed
  - Current behavior: coordinator shows warning state on partial failure; `lastSuccessAt` reflects last completed run (warning remains visible)
  - Implementation plan:
    - `SyncService.processPendingSync()` returns structured result (`pushed`, `acked`, `failed`, `pulled`)
    - `SyncCoordinatorController` sets warning/error state when `failed > 0`
    - keep `lastSuccessAt` semantics for fully-successful sync only (or split into `lastRunAt` / `lastSuccessAt`)
  - Test plan:
    - partial ACK updates warning banner
    - full success clears error and resets backoff

- [x] Sync projector strict unknown-operation/entity handling (backend)
  - Goal: no silent no-op acceptance
  - Implemented: unsupported entity/op now raises typed sync apply error and is returned via `/sync/push` `failed_events` (not ACKed)
  - Implementation plan:
    - raise typed validation error for unsupported entity/op in `sync/push`
    - include failure entry in response
  - Test plan:
    - unsupported entity rejected and not ACKed

### Priority P2 (Financial Auditability / Domain Hardening)

- [x] Unified `ledger_entries` table (backend)
  - Goal: immutable financial audit trail for sales/expenses/payments/refunds
  - Implemented:
    - new backend `ledger_entries` table/model + `LedgerService`
    - records created for `sale`, `expense`, `customer_payment`, and `refund`
    - wired for both normal API writes and sync-projected financial events
    - sqlite compat migration creates `ledger_entries` for local dev DBs
  - Implementation plan:
    - add `ledger_entries` schema (`store_id`, `entity_type`, `entity_id`, `entry_type`, `amount`, `direction`, `created_at`, metadata JSON)
    - write entries from sale/payment/expense/refund flows
    - expose ledger export/report endpoints later
  - Test plan:
    - every financial write creates exactly one or more expected ledger entries

- [x] Soft-delete strategy alignment (backend + mobile cache)
  - Goal: preserve history consistently while allowing local cache pruning
  - Implemented/standardized policy:
    - backend remains soft-delete source of truth for `products`, `customers`, `expenses`
    - mobile cache uses local tombstone for `customer` deletes (`is_deleted = 1`)
    - mobile cache prunes `product` and `expense` rows on sync `DELETE` (explicit cache policy)
    - policy documented in `docs/mobile-cache-delete-policy.md`
  - Implementation plan:
    - decide per-entity cache policy (`soft delete locally` vs `hard-delete cache only`)
    - document and standardize mobile apply behavior
    - prefer local tombstones for entities with UI/history needs
  - Test plan:
    - deleted product/customer remains hidden but audit/history remains queryable where expected

### Priority P3 (Security / Ops)

- [x] Refresh token rotation (backend)
  - Goal: rotate and revoke prior refresh token on `/auth/refresh`
  - Implemented:
    - `/auth/refresh` revokes submitted refresh token and returns rotated token pair
    - old refresh token is rejected on reuse (`TOKEN_REVOKED`)
    - JWTs now include unique `jti` so rotated refresh tokens are not identical
  - Implementation plan:
    - revoke submitted refresh token on successful refresh
    - optionally persist token family/session id for stricter replay detection
  - Test plan:
    - old refresh token rejected after refresh
    - logout revokes active refresh token as before

- [x] Local DB encryption assessment and implementation plan (mobile)
  - Goal: at-rest protection for sensitive local data
  - Current gap: plain `sqflite` database
  - Delivered:
    - assessment + recommendation doc (`SQLCipher` path)
    - migration strategy and rollout plan for existing installs
    - key storage strategy notes (Keychain/Keystore)
  - Implementation plan:
    - evaluate `sqlcipher`/encrypted SQLite support for Flutter target platforms
    - migration/backward compatibility plan for existing installs
    - key storage strategy (Keychain/Keystore via secure storage)
  - Deliverable:
    - RFC/decision doc + implementation spike before rollout

- [x] RBAC foundation (backend)
  - Goal: role-based access control for multi-user/store operations
  - Implemented foundation:
    - `users.role` column (`owner` default)
    - role exposed in `/auth/me`
    - role claim included in issued tokens
    - reusable `require_roles(...)` dependency helper
    - design doc for membership-based full RBAC rollout
  - Current limitation: no per-store membership table yet (`store_users` pending)
  - Implementation plan:
    - add roles (`owner`, `staff`, optional `viewer`)
    - enforce permission checks in sensitive endpoints (products, sales refunds, settings, exports)
    - include role claims/profile endpoint support
  - Test plan:
    - endpoint authorization matrix tests by role

### Priority P4 (Performance / Observability)

- [x] Sync chunk size tuning and config
  - Goal: adapt chunk sizes for unstable internet (`20-50` recommended baseline)
  - Implemented:
    - mobile defaults reduced to push `50`, pull `100`
    - mobile chunk sizes configurable via `dart-define`:
      - `SYNC_PUSH_CHUNK_SIZE`
      - `SYNC_PULL_CHUNK_SIZE`
    - backend `/sync/pull` default/max limits moved to config:
      - `sync_pull_default_limit` (default `100`)
      - `sync_pull_max_limit` (default `500`)
  - Implementation plan:
    - move chunk sizes to config
    - reduce defaults (e.g. push `50`, pull `100`) and measure
    - optional dynamic chunk backoff on timeout/failure

- [x] Sync telemetry / diagnostics (backend + mobile)
  - Goal: production debugging without guessing
  - Implemented:
    - backend structured sync logs for `/sync/push` and `/sync/pull` (counts + duration)
    - mobile `SyncService` run summary logs (pending/acked/failed/pulled/applied, chunk sizes, duration)
    - mobile sync coordinator logs success/failure/backoff summaries
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
  - P1 partial-sync UX semantics (2026-02-24):
    - Mobile `SyncService` returns structured sync result counts (`pending/pushed/acked/failed/pulled/applied`)
    - Sync coordinator shows warning state on partial sync failure (instead of clean success)
    - Mobile `test/integration/sync_service_test.dart` + `test/integration/sync_coordinator_test.dart` -> `All tests passed`
    - Mobile `flutter analyze` -> `No issues found!`
  - P1 conflict handling (2026-02-24):
    - Backend sync projector rejects stale `product`/`customer` UPSERTs with `CONFLICT_STALE_EVENT`
    - `/sync/push` returns conflict failures in `failed_events` (not ACKed)
    - Backend `tests/api/test_sync.py` (incl. stale conflict cases) -> `20 passed`
  - P2 auditability + delete policy alignment (2026-02-24):
    - Added backend `ledger_entries` + `LedgerService` and wired sale/expense/customer payment/refund writes (API + sync projector)
    - Added mobile cache delete policy docs (`customer` tombstone; `product`/`expense` cache prune)
    - Backend `tests/api/test_products_customers_sales_expenses_reports.py` -> `24 passed`
    - Backend `tests/api/test_sync.py` -> `21 passed`
  - P3 security/ops foundation (2026-02-24):
    - Backend refresh token rotation now revokes submitted token on `/auth/refresh` and issues rotated pair (`jti` added)
    - Added RBAC foundation (`users.role`, `/auth/me` role, token role claim, `require_roles(...)` helper)
    - Added local DB encryption assessment RFC (`docs/local-db-encryption-assessment.md`)
    - Added RBAC foundation RFC (`docs/rbac-foundation.md`)
    - Backend `tests/api/test_auth_and_store.py` -> `7 passed`
  - P4 performance/observability (2026-02-24):
    - Sync chunk sizes tuned/configurable (mobile `50/100` defaults; backend pull limit config `100/500`)
    - Backend and mobile sync telemetry logs added (run counts + duration)
    - Backend `tests/api/test_sync.py` -> `21 passed`
    - Mobile `flutter analyze` -> `No issues found!`

## Flutter Refactor Plan (Post-Backend Hardening)

Goal: align Flutter mobile architecture with the new backend/API capabilities while preserving offline-first UX.

### Flutter Refactor Priorities

- [x] F1: Sync API contract typing (mobile)
  - Add typed sync DTOs/models for:
    - `SyncPushResponse` (`ackedOpIds`, `failedEvents`)
    - `SyncFailedEvent` (`opId`, `entity`, `operation`, `code`, `message`)
    - `SyncPullResponse` (`events`, `nextCursor`)
  - Implemented:
    - added typed sync models in `mobile/lib/core/network/models/sync_models.dart`
    - `BackendGateway.pushSync()` / `pullSync()` now return typed models
    - `SyncService` consumes typed pull responses instead of loose `Map` parsing
    - sync integration test fakes updated to typed models
  - Target files:
    - `mobile/lib/core/network/backend_gateway.dart`
    - `mobile/lib/core/network/sync_service.dart`
    - new `mobile/lib/core/network/models/sync_models.dart`

- [x] F2: Sync error classification + UI messaging (mobile)
  - Map backend `failed_events.code` into typed local categories:
    - `conflict`, `validation`, `auth`, `network`, `server`
  - Implemented:
    - added `SyncErrorMapper` + typed categories/presentation model
    - backend `failed_events` now map to user-safe outbox messages (`last_error`)
    - developer detail logged separately in sync logs
    - sync coordinator failure banner now uses user-safe mapped messages
  - Target files:
    - `mobile/lib/core/network/sync_service.dart`
    - `mobile/lib/core/providers/app_providers.dart`
    - new `mobile/lib/core/sync/sync_error_mapper.dart`

- [x] F3: Session refresh-rotation hardening (mobile)
  - Ensure rotated refresh token from `/auth/refresh` always replaces old token in secure storage
  - Add explicit handling for:
    - `TOKEN_REVOKED`
    - `INVALID_TOKEN`
    - forced logout on refresh failure
  - Implemented:
    - added `SessionAuthException` in `SessionService`
    - explicit refresh failure handling for token errors (`TOKEN_REVOKED`, `INVALID_TOKEN`, `INVALID_TOKEN_TYPE`, `USER_NOT_FOUND`)
    - clears local tokens + removes auth header on auth refresh failure
    - `SyncService` now rethrows auth-session failures (instead of swallowing)
    - sync coordinator forces local logout on session auth failure
    - rotated refresh token persistence remains handled via `SecureTokenStorage.saveTokens(...)`
  - Target files:
    - `mobile/lib/core/network/session_service.dart`
    - `mobile/lib/core/storage/secure_storage.dart`

- [x] F4: RBAC readiness in Flutter (mobile)
  - Store/display current user role (`owner`/`staff`/`viewer`)
  - Gate/hide UI actions by role (foundation only)
  - First targets:
    - refunds
    - exports
    - settings business/tax
    - stock adjustment
  - Implemented (foundation):
    - `role` persisted in `AppPreferences` and carried in `AuthState`
    - role fetched from backend `/auth/me` and hydrated into auth/profile state
    - owner-only gating for key settings entries (`Business/Tax/User Management/Subscription`)
    - stock adjustment UI gated to `owner`/`staff` in product list/detail
    - role visible in profile screen (debug/visibility)
  - Note: refund/export UI gating remains pending until those UI actions are wired in current mobile screens
  - Target files:
    - `mobile/lib/core/network/session_service.dart`
    - `mobile/lib/core/providers/app_providers.dart`
    - relevant feature screens

- [x] F5: Outbox diagnostics screen (mobile)
  - Add debug/admin Sync Queue UI:
    - pending/failed rows
    - entity/op
    - retry count
    - last error
    - timestamps
  - Actions:
    - retry sync
    - copy error details
  - Implemented:
    - `Sync Diagnostics` screen with queue rows, retry counts, last errors, copy details
    - retry sync and refresh actions
    - settings entry point
    - sync debug provider module (`core/providers/sync_debug_providers.dart`)

- [x] F6: Conflict resolution UX (mobile)
  - Handle `CONFLICT_STALE_EVENT` failures with explicit UI guidance
  - First version:
    - warning banner with count
    - `pull latest + retry` action
    - “server has newer data” message
  - Later: per-entity diff/merge UI
  - Implemented:
    - conflict-aware sync banner message in app shell
    - `Pull+Retry` action label for conflict case
    - conflict rows highlighted in Sync Diagnostics

- [x] F7: Sync telemetry UI surface (mobile)
  - Extend sync status strip/debug UI with:
    - last run counts (`acked/failed/pulled`)
    - duration
    - last error summary
  - Uses existing telemetry added in `P4`
  - Implemented:
    - `SyncStatusState` stores last run counts + duration
    - app shell sync strip shows compact telemetry summary
    - diagnostics screen quick stats

- [x] F8: Ledger / audit trail feature (mobile + backend API if needed)
  - Add read-only ledger UI backed by backend `ledger_entries`
  - Screens:
    - store ledger
    - customer ledger integration
  - Add repository/providers/models for ledger endpoints
  - Implemented (v1):
    - backend `/api/v1/reports/ledger` endpoint
    - mobile ledger model + provider + ledger report screen
    - Reports screen navigation tile
  - Scope note:
    - store-level ledger UI is implemented
    - customer-ledger integration remains future polish (existing customer ledger view still available)

- [x] F9: Encrypted DB migration prep (mobile)
  - Refactor `LocalDatabase` open/init behind strategy abstraction
  - Separate:
    - DB open strategy
    - schema/migrations
    - repository runtime usage
  - Prepares SQLCipher rollout from `P3` RFC
  - Implemented:
    - `DatabaseOpenStrategy` abstraction + default `SqfliteDatabaseOpenStrategy`
    - `LocalDatabase` now uses pluggable DB open strategy

- [x] F10: Provider/module cleanup (mobile)
  - Split large `app_providers.dart` into smaller modules:
    - auth/session
    - sync
    - reports/dashboard
    - feature providers
  - Goal: reduce coupling and make future changes safer
  - Implemented (foundation split):
    - `core/providers/sync_debug_providers.dart`
    - `core/providers/auth_role_providers.dart`
    - screens updated to consume split provider modules
  - Scope note:
    - full `app_providers.dart` decomposition remains future cleanup

### Flutter Refactor Execution Order (Recommended)

1. F1 Sync API contract typing
2. F2 Sync error classification + messaging
3. F3 Session refresh-rotation hardening
4. F4 RBAC readiness in Flutter
5. F5 Outbox diagnostics screen
6. F6 Conflict resolution UX
7. F7 Sync telemetry UI surface
8. F8 Ledger / audit trail feature
9. F9 Encrypted DB migration prep
10. F10 Provider/module cleanup

### Flutter Refactor Progress Notes

- F1 sync API contract typing (2026-02-24):
  - Added typed sync DTOs (`SyncPushResponseModel`, `SyncPushFailure`, `SyncPullResponseModel`, `SyncPullEventModel`)
  - Moved sync response parsing from `SyncService` to `BackendGateway`
  - Updated `test/integration/sync_service_test.dart` fakes for typed gateway responses
  - Mobile `flutter analyze` -> `No issues found!`
- F2 sync error classification + UI messaging (2026-02-24):
  - Added `SyncErrorMapper` (`conflict/validation/auth/network/server`)
  - `SyncService` now stores user-safe sync failure messages in outbox and logs developer details
  - `SyncCoordinatorController` now maps exceptions to user-safe sync banner messages
  - Mobile `flutter analyze` -> `No issues found!`
  - Mobile `test/integration/sync_service_test.dart` -> `All tests passed`
  - Mobile `test/integration/sync_coordinator_test.dart` -> `All tests passed`
- F3 session refresh-rotation hardening (2026-02-24):
  - Added typed `SessionAuthException` and explicit token-auth failure handling in `SessionService`
  - Sync auth bootstrap failures now propagate to coordinator and trigger forced local logout
  - Mobile `flutter analyze` -> `No issues found!`
  - Mobile `test/integration/sync_coordinator_test.dart` -> `All tests passed`
- F4 RBAC readiness in Flutter (2026-02-24):
  - Added role persistence (`AppPreferences`) + role-aware `AuthState` helpers
  - Hydrated role from backend `/auth/me` into auth/profile state
  - Gated owner-only settings actions and stock adjustment actions (`owner`/`staff`)
  - Mobile `flutter analyze` -> `No issues found!`
- F5-F10 remaining Flutter refactor items (2026-02-24):
  - Added Sync Diagnostics screen + debug providers (queue rows, retries, errors, copy detail)
  - Added conflict-aware sync banner UX and telemetry summary in app shell
  - Added backend `/reports/ledger` + mobile ledger report screen/provider/tile
  - Added `DatabaseOpenStrategy` seam for future SQLCipher migration
  - Added provider split foundation modules (`sync_debug_providers`, `auth_role_providers`)
  - Mobile `flutter analyze` -> `No issues found!`

## Intelligence + Risk Layer Plan (Post-v1 Core)

Spec source:
- `docs/intelligence-risk-layer.md`

Goal:
- Add explainable business intelligence + credit risk features on top of the current offline-first ledger/inventory/sales stack.

### Delivery Tracker (Intelligence/Risk)

- [x] IR0: Foundations / data contract alignment (customer-metrics/alerts initial slice)
- [x] IR1: Data model extensions (backend + local SQLite cache tables) (customer-metrics/alerts initial slice)
- [x] IR2: Deterministic metrics engine (server) (v1 core)
- [ ] IR3: Local metrics cache + offline compute (mobile)
- [ ] IR4: Sync transport for metrics + alerts
- [x] IR5: Credit aging report + customer risk score UI (v1 core)
- [ ] IR6: Business Health dashboard + alerts feed (in progress)
- [x] IR7: Profit-by-product + dead stock + expense spike insights (v1 core)
- [ ] IR8: Testing + consistency validation + rollout (in progress)

### IR0: Foundations / Data Contract Alignment (P0)

- Lock metric names and formulas with the spec:
  - credit aging buckets
  - risk score inputs (A/B/C/D)
  - risk level thresholds
  - dead stock default days
  - expense spike thresholds
- Decide server-vs-local authority for each metric:
  - server authoritative for synced/cross-device metrics
  - local cache for offline display
- Add versioning to computed metric payloads:
  - `metrics_version`
  - `computed_at`
- Define API/transport contract:
  - `/metrics/business`
  - `/metrics/customers`
  - `/metrics/products`
  - `/alerts`
  - optional sync-event transport through `/sync/pull`

### IR1: Data Model Extensions (P0/P1)

Backend (SQLAlchemy + DB)
- `products`:
  - `cost_price` (verify complete coverage already present)
  - `last_movement_at`
  - `dead_stock_days_override` (optional)
- `sales`:
  - `due_date` (optional)
- New cached tables:
  - `customer_metrics`
  - `product_metrics`
  - `business_metrics`
  - `alerts`

Mobile (SQLite cache)
- Add local cache tables mirroring backend computed outputs:
  - `customer_metrics`
  - `product_metrics`
  - `business_metrics`
  - `alerts`
- Add migrations + tests for all new tables/columns

### IR2: Deterministic Metrics Engine (Server) (P0)

Implement server-side rule-based computation services:
- Credit aging buckets (timezone-safe)
- Customer credit risk score:
  - `oldest_due_days`
  - `avg_days_to_pay`
  - `on_time_rate`
  - outstanding spike factor
  - score + level + explanation factors
- Product metrics:
  - qty/revenue/profit windows
  - `last_sale_at`
  - dead stock flag/value
- Business metrics:
  - sales / expenses / profit / margin
  - outstanding / overdue
  - cash risk level (v1 simple heuristic)
- Alerts generator (deterministic):
  - overdue credit
  - low stock
  - dead stock
  - expense spike
  - margin drop (if available in v1)

Implementation notes
- Keep formulas in one service layer (no duplication in API routes)
- Add explicit clock/date boundary helpers (reuse timezone-safe patterns)
- Make outputs explainable (store factor values + reasons)

### IR3: Local Metrics Cache + Offline Compute (Mobile) (P1)

Local-first metrics behavior
- Compute simplified local metrics after local writes:
  - sale create
  - customer payment
  - expense create
  - stock adjust
  - product price/cost change
- Write into local metrics cache tables for instant UI
- Mark metrics as provisional/offline if server recompute not yet synced

Refactor tasks
- Add `MetricsRepository` + `AlertsRepository`
- Add local compute helpers:
  - credit aging
  - risk score (same formula as backend)
  - dead stock
  - basic profit by product
- Recompute triggers integrated into existing repositories/controllers

### IR4: Sync Transport for Metrics + Alerts (P1)

Option A (recommended v1)
- Dedicated pull endpoints:
  - `/metrics/business`
  - `/metrics/customers`
  - `/metrics/products`
  - `/alerts`

Option B (later optimization)
- Transport metrics/alerts through `/sync/pull` events

Mobile integration
- Fetch server-authoritative metrics after successful sync
- Overwrite local metrics cache tables atomically
- Invalidate only metrics-related providers (avoid broad UI churn)

### IR5: Credit Aging Report + Customer Risk UI (P0 user value)

Features
- Credit Aging report screen:
  - bucket totals (0-7, 8-30, 31-60, 60+)
  - customer breakdown
  - filters (`overdue only`, `high risk only`)
- Customer risk badge + score:
  - customer list
  - customer detail
  - credit report list
  - credit sale flow warning
- Risk explanation panel:
  - overdue days
  - on-time rate
  - avg days to pay
  - outstanding vs normal

### IR6: Business Health Dashboard + Alerts Feed (P0/P1)

New dashboard/tab
- Profit snapshot
- Cash outlook (simple heuristic)
- Credit risk summary
- Stock health summary
- Alerts feed with CTA actions

Mobile UI tasks
- New feature module:
  - `features/intelligence/` or `features/business_health/`
- Provider layer:
  - `businessMetricsProvider`
  - `customerRiskSummaryProvider`
  - `stockHealthProvider`
  - `alertsProvider`
- CTA routing:
  - open customer/product/report screens from alert actions

### IR7: Product Profit / Dead Stock / Expense Spike Insights (P1)

Reports / insights
- Profit by product (requires `cost_price`)
- Dead stock report:
  - list + value locked
- Expense spike alerts/report by category

Data integrity checks
- Profit totals should reconcile with ledger/sales + known assumptions
- Handle missing `cost_price` gracefully:
  - hide margin/profit or mark as partial

### IR8: Testing + Consistency Validation + Rollout (P0/P1)

Backend unit tests
- credit aging bucket logic
- risk score formula factors + thresholds
- on-time rate + avg days to pay
- dead stock classification
- expense spike trigger logic

Backend integration tests
- metrics endpoints return deterministic values for seeded scenarios
- alerts generation correctness
- timezone/date-boundary scenarios

Mobile tests
- local metrics compute correctness
- local vs server overwrite behavior
- sync-triggered metrics cache refresh
- UI badges / filters / alert CTA rendering

Regression / consistency tests
- metrics totals match ledger totals (within defined assumptions)
- no mismatch between report periods and metrics periods
- offline-create -> sync -> server metrics overwrite local provisional values

Rollout plan
- Phase-gate by feature flags:
  - risk badges
  - business health dashboard
  - alerts feed
- Start with read-only analytics and warnings before credit-limit enforcement

### Recommended Implementation Order (Intelligence/Risk)

1. IR0 contract alignment + formulas
2. IR1 schema/cache tables + migrations
3. IR2 server metrics engine (credit aging + customer risk first)
4. IR4 metrics endpoints + mobile cache sync
5. IR5 credit aging report + customer risk badges
6. IR6 business health dashboard + alerts feed
7. IR7 dead stock / profit-by-product / expense spikes
8. IR8 full test pass + rollout flags

### Immediate Next Slice (Suggested)

- [x] Implement IR0/IR1 for `customer_metrics` + `alerts` only (smallest high-value slice)
- [x] Build server credit aging + customer risk score service (IR2 partial)
- [x] Add `/metrics/customers` endpoint + mobile risk badge in customer list/detail (IR4/IR5 partial)
- [x] Add credit aging report screen (IR5 partial)

### Intelligence/Risk Progress Notes

- IR0/IR1 foundations started (2026-02-24):
  - Added spec doc: `docs/intelligence-risk-layer.md`
  - Backend schema foundations:
    - new SQLAlchemy models: `Alert`, `CustomerMetric`
    - SQLite compat creation for `alerts` and `customer_metrics`
    - startup model registration hardened in `app/main.py` (`import app.models`)
  - Backend service skeleton:
    - new `IntelligenceService` with v1 customer risk score formula helper (`score_customer_risk`)
    - persistence helpers for `customer_metrics` and generated `alerts`
  - Mobile local cache foundations:
    - SQLite DB version `8`
    - added local cache tables: `customer_metrics`, `alerts`
    - added migration + indexes
  - Validation:
    - backend import smoke -> `ok`
    - mobile `flutter analyze` (`local_db.dart`) -> `No issues found!`
- IR2/IR4/IR5 first backend metrics slice (2026-02-24):
  - Added backend customer metrics schemas:
    - `backend/app/schemas/metrics.py`
  - Added backend metrics API router:
    - `GET /api/v1/metrics/customers`
    - supports `overdue_only`, `high_risk_only`, `limit`
  - Implemented deterministic customer credit aging + risk scoring (server):
    - FIFO payment allocation over credit sales
    - aging buckets (`0-7`, `8-30`, `31-60`, `60+`)
    - v1 risk score factors A/B/C/D per spec
    - persists cache rows in `customer_metrics`
    - files:
      - `backend/app/services/intelligence_service.py`
      - `backend/app/api/metrics.py`
  - Wired backend router + exports:
    - `backend/app/main.py`
    - `backend/app/api/__init__.py`
    - `backend/app/schemas/__init__.py`
  - Validation:
    - backend import smoke -> `ok`
  - Scope note:
    - mobile risk badge UI is still pending (next slice)
    - metrics currently computed on demand in endpoint and cached
  - Backend `tests/api/test_products_customers_sales_expenses_reports.py` -> `24 passed`
  - Backend import smoke check -> `ok`
- IR4/IR5 mobile customer risk badge slice (2026-02-24):
  - Added mobile customer risk metric model:
    - `mobile/lib/features/customers/domain/customer_risk_metric.dart`
  - Added backend client method:
    - `BackendGateway.getCustomerMetrics(...)`
    - file: `mobile/lib/core/network/backend_gateway.dart`
  - Added provider:
    - `customerRiskMetricsProvider` (maps by `customer_id`)
    - file: `mobile/lib/core/providers/app_providers.dart`
  - Added sync refresh integration:
    - invalidates `customerRiskMetricsProvider` after successful sync
  - Added customer risk badges UI:
    - customer list (`CustomersScreen`)
    - customer detail header (`CustomerDetailScreen`)
    - files:
      - `mobile/lib/features/customers/presentation/customers_screen.dart`
      - `mobile/lib/features/customers/presentation/customer_detail_screen.dart`
  - Validation:
    - Backend targeted test `tests/api/test_products_customers_sales_expenses_reports.py` -> `25 passed`
    - Mobile targeted `flutter analyze` (metrics client/provider + customer screens) -> `No issues found!`
  - Scope note:
    - credit aging report screen is still pending (next IR5 slice)
- IR5 credit aging report UI slice (2026-02-24):
  - Added `CreditAgingReportScreen` with:
    - bucket totals (`0-7`, `8-30`, `31-60`, `60+`)
    - customer breakdown cards
    - filters: `Overdue Only`, `High Risk Only`
    - navigation to `CustomerDetailScreen`
    - file: `mobile/lib/features/reports/presentation/credit_aging_report_screen.dart`
  - Added metrics report provider family:
    - `customerMetricsReportProvider(CustomerMetricsQueryParams)`
    - file: `mobile/lib/core/providers/app_providers.dart`
  - Added Reports entry tile:
    - `Credit Aging` in `ReportsScreen`
    - file: `mobile/lib/features/reports/presentation/reports_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (credit aging screen + reports/provider files) -> `No issues found!`
  - Scope note:
    - IR5 still has pending polish/features:
      - credit sale flow risk warning
- IR5 risk UI polish slice (2026-02-24):
  - Added customer risk badge in `CreditReportScreen` list items
    - file: `mobile/lib/features/reports/presentation/credit_report_screen.dart`
  - Expanded mobile customer risk model with explainability fields + factors:
    - `avg_days_to_pay`, `on_time_rate`, `payment_frequency_30d`
    - factor payloads (`oldest_due_factor`, `avg_days_to_pay_factor`, `late_behavior_factor`, `outstanding_spike_factor`)
    - file: `mobile/lib/features/customers/domain/customer_risk_metric.dart`
  - Added `Risk Explanation` panel to `CustomerDetailScreen` (A/B/C/D-style reasons)
    - file: `mobile/lib/features/customers/presentation/customer_detail_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (customer risk model + credit report + customer detail) -> `No issues found!`
  - Scope note:
    - IR5 still pending: credit sale flow risk warning before confirming credit sale
- IR5 credit sale warning slice (2026-02-24):
  - Added risk warning confirmation before saving quick credit sale
    - checks existing customer match by phone/name
    - warns on medium/high risk (`yellow`/`red`) before continuing
    - implemented in both sales entry screens:
      - `mobile/lib/features/sales/presentation/create_sale_screen.dart`
      - `mobile/lib/features/sales/presentation/sales_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (both sales screens) -> `No issues found!`
  - Scope note:
    - warning is confirm-only (does not block); credit limit enforcement remains future work (`IR6/IR7+`)
- IR6 alerts feed slice (2026-02-24):
  - Backend:
    - Added `GET /api/v1/alerts` (v1 supports `status=open`)
    - deterministically generates/caches open credit-risk alerts from customer metrics
    - files:
      - `backend/app/api/alerts.py`
      - `backend/app/schemas/alerts.py`
      - `backend/app/services/intelligence_service.py`
      - router wiring in `backend/app/main.py`, `backend/app/api/__init__.py`, `backend/app/schemas/__init__.py`
  - Backend test:
    - added `test_alerts_open_returns_credit_overdue_alerts(...)`
    - file: `backend/tests/api/test_products_customers_sales_expenses_reports.py`
    - result: `uv run pytest ...test_products_customers_sales_expenses_reports.py -q` -> `26 passed`
  - Mobile:
    - Added alerts model + backend client + provider:
      - `mobile/lib/features/reports/domain/alert_item.dart`
      - `BackendGateway.getAlerts(...)`
      - `alertsFeedProvider`
    - Added `AlertsFeedScreen` and Reports entry tile
      - `mobile/lib/features/reports/presentation/alerts_feed_screen.dart`
      - `mobile/lib/features/reports/presentation/reports_screen.dart`
  - Validation:
    - backend import smoke -> `ok`
    - mobile targeted `flutter analyze` (alerts model/client/provider/UI) -> `No issues found!`
  - Scope note:
    - this is alerts-feed v1 (credit-risk alerts only); Business Health dashboard cards/summary are still pending IR6 slices
- IR6 Business Health screen slice (2026-02-24):
  - Added `BusinessHealthScreen` (v1 partial) combining existing providers:
    - profit snapshot (`dashboardSummaryProvider`)
    - credit risk summary (`/metrics/customers` via `customerMetricsReportProvider`)
    - stock health preview (`lowStockProductsProvider`)
    - alerts preview (`alertsFeedProvider`)
    - file: `mobile/lib/features/reports/presentation/business_health_screen.dart`
  - Added Reports entry tile:
    - `Business Health` in `mobile/lib/features/reports/presentation/reports_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (business health + reports screen) -> `No issues found!`
  - Scope note:
    - IR6 still pending for fuller spec alignment:
      - cash outlook heuristic
      - stock health metrics (`dead stock`, `fast movers`) summaries
      - alert CTA routing actions beyond preview
- IR6 backend business metrics slice (2026-02-24):
  - Backend:
    - Added `GET /api/v1/metrics/business`
    - returns canonical Business Health summary (sales/expenses/profit/margin, outstanding/overdue, low-stock/dead-stock/high-risk counts, open alerts count, simple cash risk level + reasons)
    - files:
      - `backend/app/api/metrics.py`
      - `backend/app/schemas/metrics.py`
      - `backend/app/schemas/__init__.py`
  - Backend tests:
    - added `test_metrics_business_returns_summary_and_risk_counts(...)`
    - file: `backend/tests/api/test_products_customers_sales_expenses_reports.py`
    - result: `uv run pytest ...test_products_customers_sales_expenses_reports.py -q` -> `29 passed`
  - Validation:
    - backend import smoke -> `ok`
  - Scope note:
    - current cash risk is a simple heuristic (v1), not yet the richer cash outlook model from the spec
- IR6 Business Health provider migration slice (2026-02-24):
  - Mobile:
    - added `BackendGateway.getBusinessMetrics(...)`
    - added `businessMetricsProvider`
    - `BusinessHealthScreen` now uses `/metrics/business` for canonical top summary + cash risk/reasons (instead of composing that section from local-only dashboard data)
    - sync coordinator now invalidates `businessMetricsProvider` after successful sync
    - files:
      - `mobile/lib/core/network/backend_gateway.dart`
      - `mobile/lib/core/providers/app_providers.dart`
      - `mobile/lib/features/reports/presentation/business_health_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (business metrics client/provider/screen) -> `No issues found!`
  - Scope note:
    - IR6 still in progress: richer cash outlook model and alert CTA routing remain pending
- IR7 product insights slice (2026-02-24):
  - Backend:
    - Added `GET /api/v1/metrics/products`
      - qty sold (30d window)
      - revenue/profit per product (uses `cost_price` when available)
      - `last_sale_at`
      - dead stock detection + dead stock value
    - files:
      - `backend/app/api/metrics.py`
      - `backend/app/schemas/metrics.py`
      - `backend/app/services/intelligence_service.py`
  - Backend tests:
    - added `test_metrics_products_returns_profit_and_dead_stock(...)`
    - file: `backend/tests/api/test_products_customers_sales_expenses_reports.py`
    - result: `uv run pytest ...test_products_customers_sales_expenses_reports.py -q` -> `27 passed`
  - Mobile:
    - added product metrics model/client/provider:
      - `mobile/lib/features/reports/domain/product_metric_item.dart`
      - `BackendGateway.getProductMetrics(...)`
      - `productMetricsReportProvider(ProductMetricsQueryParams)`
    - added `ProductInsightsReportScreen` (profit by product + dead stock v1)
      - `mobile/lib/features/reports/presentation/product_insights_report_screen.dart`
    - added Reports entry tile
      - `mobile/lib/features/reports/presentation/reports_screen.dart`
  - Validation:
    - backend import smoke -> `ok`
    - mobile targeted `flutter analyze` (product metrics client/provider/UI) -> `No issues found!`
  - Scope note:
    - IR7 still pending:
      - stronger profit reconciliation/assumption labeling in UI
- IR7 fast movers slice (2026-02-24):
  - Backend:
    - extended `/metrics/products` with `qty_sold_7d` for fast-mover ranking
    - files:
      - `backend/app/services/intelligence_service.py`
      - `backend/app/api/metrics.py`
      - `backend/app/schemas/metrics.py`
  - Backend tests:
    - expanded product metrics test to assert `qty_sold_7d`
    - file: `backend/tests/api/test_products_customers_sales_expenses_reports.py`
    - result: `uv run pytest ...test_products_customers_sales_expenses_reports.py -q` -> `28 passed`
  - Mobile:
    - extended product metrics model with `qtySold7d`
    - added fast movers preview to:
      - `ProductInsightsReportScreen`
      - `BusinessHealthScreen`
    - files:
      - `mobile/lib/features/reports/domain/product_metric_item.dart`
      - `mobile/lib/features/reports/presentation/product_insights_report_screen.dart`
      - `mobile/lib/features/reports/presentation/business_health_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (product metrics model + Product Insights + Business Health + provider/client deps) -> `No issues found!`
  - Scope note:
- IR7 profit assumption labeling slice (2026-02-24):
  - Added explicit profit/reconciliation notes in:
    - `ProductInsightsReportScreen` (cost-price based estimate, excludes allocated expenses, missing cost-price caveat)
    - `BusinessHealthScreen` (today operational estimate vs product-level profit differences)
  - Files:
    - `mobile/lib/features/reports/presentation/product_insights_report_screen.dart`
    - `mobile/lib/features/reports/presentation/business_health_screen.dart`
  - Validation:
    - mobile targeted `flutter analyze` (Product Insights + Business Health) -> `No issues found!`
  - Scope note:
    - IR7 v1 core slices are now implemented; future enhancement is richer reconciliation screens/labels, not blocker for current rollout
- IR8 intelligence/risk unit test slice (2026-02-24):
  - Added backend unit tests for `IntelligenceService`:
    - credit aging bucket boundaries
    - risk score level thresholds + clamping
    - timezone-safe day-delta behavior (date-based)
    - expense spike trigger thresholds
  - File:
    - `backend/tests/unit/test_intelligence_service.py`
  - Validation:
    - `uv run pytest .../backend/tests/unit/test_intelligence_service.py -q` -> `5 passed`
  - Scope note:
    - IR8 still pending broader integration/regression coverage:
      - local-vs-server metrics consistency tests
      - mobile metrics cache overwrite tests
      - rollout flags/feature gating
- IR8 metrics integration test slice (2026-02-24):
  - Added backend integration tests for intelligence metrics API behavior:
    - `/metrics/business` date-range filtering (`from/to`) for sales/expenses
    - `/metrics/products` 7-day boundary behavior (`qty_sold_7d`) and windowed quantity aggregation (`window_days`)
  - File:
    - `backend/tests/api/test_products_customers_sales_expenses_reports.py`
  - Validation:
    - `uv run pytest .../backend/tests/api/test_products_customers_sales_expenses_reports.py -q` -> `31 passed`
  - Scope note:
    - field name `qty_sold_30d` is currently used as a backward-compatible response key even when `window_days` is changed (documented in test)
- IR8 mobile intelligence UI test slice (2026-02-24):
  - Added mobile widget/integration tests for intelligence/risk screens:
    - `BusinessHealthScreen` renders canonical business metrics summary and risk/alert signals from provider overrides
    - `ProductInsightsReportScreen` renders top-profit + fast-mover sections and dead-stock summary
  - File:
    - `mobile/test/integration/intelligence_ui_test.dart`
  - Validation:
    - `flutter test .../mobile/test/integration/intelligence_ui_test.dart` -> `All tests passed!`
  - Scope note:
    - assertions intentionally target stable visible UI text (not off-screen list items) to reduce flaky viewport-dependent failures
- IR8 mobile intelligence provider refresh test slice (2026-02-24):
  - Added mobile integration/provider tests for intelligence/risk provider surfaces:
    - `businessMetricsProvider`
    - `alertsFeedProvider`
    - `productMetricsReportProvider(ProductMetricsQueryParams)`
  - Coverage:
    - recompute after provider invalidation
    - typed alert-item delivery contract in consumer overrides
  - File:
    - `mobile/test/integration/intelligence_providers_test.dart`
  - Validation:
    - `flutter test .../mobile/test/integration/intelligence_providers_test.dart` -> `All tests passed!`
  - Scope note:
    - refresh/invalidation behavior is covered via provider overrides; backend parsing/sorting paths are covered separately in backend API tests and mobile UI/provider usage tests
- IR8 targeted intelligence regression pass (2026-02-24):
  - Backend:
    - `uv run pytest backend/tests/unit/test_intelligence_service.py backend/tests/api/test_products_customers_sales_expenses_reports.py -q` -> `36 passed`
    - backend import smoke -> `ok`
  - Mobile:
    - `flutter test mobile/test/integration/intelligence_ui_test.dart mobile/test/integration/intelligence_providers_test.dart` -> `All tests passed!`
  - Scope note:
    - IR8 targeted intelligence paths are now covered across backend unit/API tests and mobile UI/provider tests
    - remaining IR8 work is broader rollout/feature-flag strategy and local-vs-server metrics cache overwrite flow (IR3/IR4 coupling)
- IR3/IR4 local intelligence cache overwrite + offline fallback slice (2026-02-24):
  - Mobile sync (`SyncService`)
    - after successful sync run, fetches canonical `/metrics/customers` and `/alerts`
    - overwrites local `customer_metrics` and `alerts` cache tables in a transaction
    - cache refresh failures are non-fatal and logged (`app.sync`)
    - file:
      - `mobile/lib/core/network/sync_service.dart`
  - Mobile provider fallback (offline behavior)
    - `customerRiskMetricsProvider` falls back to local `customer_metrics`
    - `customerMetricsReportProvider(...)` falls back to local cached metrics + customer join (with approximate per-customer aging buckets derived from `oldest_due_days`)
    - `alertsFeedProvider` falls back to local `alerts` cache
    - file:
      - `mobile/lib/core/providers/app_providers.dart`
  - Tests:
    - `sync_service_test.dart`: added `successful sync overwrites local customer_metrics and alerts caches`
    - `intelligence_providers_test.dart`: added offline fallback test for customer metrics + alerts providers
  - Validation:
    - `flutter test .../mobile/test/integration/sync_service_test.dart .../mobile/test/integration/intelligence_providers_test.dart` -> `All tests passed!`
    - `flutter analyze .../mobile/lib/core/network/sync_service.dart .../mobile/lib/core/providers/app_providers.dart` -> `No issues found!`
  - Scope note:
    - local `customer_metrics` cache currently stores risk metrics, not exact per-invoice aging splits; offline Credit Aging report uses a documented bucket approximation from `oldest_due_days`
- IR4 local product/business metrics cache overwrite + offline fallback slice (2026-02-24):
  - Mobile local DB schema:
    - DB version `8 -> 9`
    - added `product_metrics` cache table
    - added `business_metrics_cache` table
    - file:
      - `mobile/lib/core/storage/local_db.dart`
  - Mobile sync (`SyncService`)
    - intelligence cache refresh now also fetches and overwrites:
      - `/metrics/products` -> `product_metrics`
      - `/metrics/business` -> `business_metrics_cache`
    - file:
      - `mobile/lib/core/network/sync_service.dart`
  - Mobile provider fallback (offline behavior)
    - `productMetricsReportProvider(...)` falls back to local `product_metrics`
    - `businessMetricsProvider` falls back to local `business_metrics_cache`
    - file:
      - `mobile/lib/core/providers/app_providers.dart`
  - Tests:
    - extended `sync_service_test.dart` cache-overwrite test to assert product + business metrics caches
    - extended `intelligence_providers_test.dart` offline fallback test to assert product metrics + business metrics providers
  - Validation:
    - `flutter test .../mobile/test/integration/sync_service_test.dart .../mobile/test/integration/intelligence_providers_test.dart` -> `All tests passed!`
    - `flutter analyze .../mobile/lib/core/storage/local_db.dart .../mobile/lib/core/network/sync_service.dart .../mobile/lib/core/providers/app_providers.dart` -> `No issues found!`
  - Scope note:
    - current cached `business_metrics` uses a single `default` cache key (no date-range variants yet); acceptable for current Business Health v1 screen which uses the default period
- IR6/IR8 cached-intelligence UI hint slice (2026-02-24):
  - Mobile UI:
    - `BusinessHealthScreen` shows an offline/cached-data banner when any intelligence provider payload reports `source = local_cache`
    - `ProductInsightsReportScreen` shows an offline/cached-data banner when product metrics payload reports `source = local_cache`
    - files:
      - `mobile/lib/features/reports/presentation/business_health_screen.dart`
      - `mobile/lib/features/reports/presentation/product_insights_report_screen.dart`
  - Tests:
    - updated `mobile/test/integration/intelligence_ui_test.dart` to assert cached-data hints render for local-cache payloads
  - Validation:
    - `flutter analyze .../business_health_screen.dart .../product_insights_report_screen.dart` -> `No issues found!`
    - `flutter test .../mobile/test/integration/intelligence_ui_test.dart` -> `All tests passed!`
  - Scope note:
    - `CreditAgingReportScreen` currently uses the local fallback but does not yet show a cached-data banner (future polish)
- IR6 alert CTA routing slice (2026-02-24):
  - Mobile:
    - added `AlertActionRouter` helper for alert actions:
      - `open_customer`
      - `open_product`
      - `view_report` (basic report targets)
    - wired alert taps + `Open` CTA button in `AlertsFeedScreen`
    - wired alert preview row taps in `BusinessHealthScreen`
    - files:
      - `mobile/lib/features/reports/presentation/alert_action_router.dart`
      - `mobile/lib/features/reports/presentation/alerts_feed_screen.dart`
      - `mobile/lib/features/reports/presentation/business_health_screen.dart`
  - Validation:
    - `flutter analyze .../alert_action_router.dart .../alerts_feed_screen.dart .../business_health_screen.dart` -> `No issues found!`
    - `flutter test .../mobile/test/integration/intelligence_ui_test.dart` -> `All tests passed!`
  - Scope note:
    - current `view_report` routing covers common report keys; unsupported alert actions still show a user-safe snackbar
- IR6 cached-data banner parity slice (2026-02-24):
  - Mobile UI:
    - added cached/offline data hint banner to `CreditAgingReportScreen` when `customerMetricsReportProvider(...)` payload has `source = local_cache`
    - file:
      - `mobile/lib/features/reports/presentation/credit_aging_report_screen.dart`
  - Tests:
    - expanded `mobile/test/integration/intelligence_ui_test.dart` with `CreditAgingReportScreen` cached-banner widget test
  - Validation:
    - `flutter analyze .../mobile/lib/features/reports/presentation/credit_aging_report_screen.dart` -> `No issues found!`
    - `flutter test .../mobile/test/integration/intelligence_ui_test.dart` -> `All tests passed!`
  - Scope note:
    - cached-data banner parity now exists across Business Health, Product Insights, and Credit Aging screens
- IR7 expense spike alerts slice (2026-02-24):
  - Backend:
    - Added deterministic expense-spike alert generation (current week vs previous 4-week average)
    - integrated into `/alerts` pipeline (`compute_and_cache_open_alerts`)
    - file: `backend/app/services/intelligence_service.py`
  - Backend tests:
    - added `test_alerts_open_includes_expense_spike_alert(...)`
    - file: `backend/tests/api/test_products_customers_sales_expenses_reports.py`
    - result: `uv run pytest ...test_products_customers_sales_expenses_reports.py -q` -> `28 passed`
  - Mobile impact:
    - no code changes required; existing Alerts Feed and Business Health alerts preview render the new `expense_spike` alerts automatically
  - Scope note:
    - IR7 still pending:
      - fast movers summary
      - stronger profit reconciliation/assumption labeling in UI
