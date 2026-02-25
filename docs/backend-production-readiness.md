# Backend Production Readiness

Status date: February 24, 2026

This checklist reflects current implementation state.

## Implemented (v1)

1. Pagination standard
- Implemented on: `GET /products`, `GET /customers`, `GET /sales`, `GET /expenses`, ledger and stock-history views.
- Shape:
```json
{
  "items": [],
  "total": 120,
  "page": 1,
  "page_size": 20
}
```

2. Soft delete strategy
- Products: implemented (`is_deleted`, `deleted_at`).
- Customers: implemented (`is_deleted`, `deleted_at`) with `409 CUSTOMER_HAS_BALANCE` guard.

3. Audit fields
- Core write models include `created_by`, `updated_by`, `device_id`, and `deleted_at` where applicable.

4. Idempotency key for sales
- Implemented via `Idempotency-Key` header.
- DB uniqueness: `(store_id, idempotency_key)`.

5. Rate limiting
- Auth endpoints protected by IP-based limiter (MVP in-memory).

6. Structured errors
- Standardized machine-readable code + detail payload.

7. Versioning
- Current namespace: `/api/v1`.
- Future breaking changes target `/api/v2`.

8. Core business completeness
- Split sale payments (`CASH|QR|BANK|CREDIT`) with credit balance handling.
- Refund endpoint with stock restock and customer credit adjustment.
- Customer payment endpoint and ledger history.
- Manual stock adjustment + stock movement history.
- Low stock, cashbook, top-products reports.
- Full JSON export endpoint.
- Device registration/list.
- Auth hardening endpoints: logout + change-password (+ pilot stubs for forgot/reset).
- Sync status endpoint.
- Intelligence/risk metrics endpoints:
  - `/metrics/business`
  - `/metrics/customers`
  - `/metrics/products`
  - `/alerts`

9. Offline/sync protocol hardening
- Cursor-based sync pull (`next_cursor`) with `since` fallback compatibility.
- Chunked sync push/pull for unstable internet.
- Per-event ACK by `op_id` and `device_id + op_id` idempotency semantics.
- Structured sync failures (`failed_events`) for invalid/conflict payloads.
- Core entity projectors for product/customer/sale/expense/customer_payment (+ tombstones).

10. Ledger / audit trail baseline
- `ledger_entries` unified financial audit trail (sales, refunds, customer payments, expenses, sync-projected financial events).

11. Auth/session hardening
- Refresh-token rotation implemented (old refresh token revoked on refresh).
- JWT tokens include role claim (RBAC foundation).

## Partially implemented / pilot-only

1. Forgot/reset password
- Endpoints exist as pilot stubs; OTP flow not implemented yet.

2. Password policy hardening
- Minimum length enforced; complexity/lockout policy pending.

3. RBAC enforcement
- Foundation exists (`users.role`, auth/profile role exposure, dependency helper),
- but endpoint-by-endpoint permission enforcement is still a future rollout.

## Planned (next phases)

1. Full RBAC enforcement (`owner|staff|accountant`) and permission mapping.
2. Subscription/billing enforcement.
3. File upload service (`/files/upload`).
4. CSV/zip export variants (`/exports/csv`).
5. Monitoring/alerts with persistent metrics stack.
6. Backup-restore runbook + RTO/RPO drills.

## Security posture summary

- JWT refresh revocation list implemented (`/auth/logout`) and refresh rotation revokes the old token.
- CORS allowlist configurable through app settings.
- PII masking/log policy requires dedicated implementation pass.

## Transaction & consistency guarantees

- Sale creation is transactional with stock updates and balance impact.
- Refund creation is transactional with stock restoration and credit correction.
- Store-level isolation is enforced in endpoint queries.
- Sync push processing:
  - per-event validation with explicit failures (no silent ACK for invalid events)
  - strict sale projector guards to avoid partial apply on invalid payloads
  - atomic/guarded stock deductions in critical paths
