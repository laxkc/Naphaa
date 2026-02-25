# SME Digital Test Strategy

Status date: February 24, 2026

## 1. Goals

- Prevent data loss.
- Guarantee stock and credit correctness.
- Keep offline sync idempotent and stable.
- Ensure Android + iOS behavior parity for core flows.

## 2. Test Layers

1. Unit tests
2. API integration tests (backend)
3. Mobile widget/integration tests
4. Manual E2E pilot checks

## 3. Backend Strategy (FastAPI)

### 3.1 Scope

Mandatory API coverage:

- Auth: register/login/refresh/me/logout/change-password
- Store CRUD (`me`, update)
- Products: CRUD + adjust-stock + stock-history + search/sort/pagination
- Customers: CRUD + payments + ledger + search/sort/pagination + soft-delete guard
- Sales: create (idempotency + split payments), list/get, refund
- Expenses: create/list/get with pagination + search
- Reports: summary, low-stock, cashbook, top-products
- Export: full JSON
- Devices: register/list
- Sync: push/pull/status

### 3.2 Core business assertions

- Stock never negative.
- Credit portion of sale increases customer balance.
- Customer payment reduces balance and cannot exceed it.
- Refund restores stock and reduces totals/credit appropriately.
- Duplicate sales are prevented by idempotency key.
- Duplicate sync events are deduped by fingerprint.

### 3.3 Current automated status (latest verified)

- Backend targeted intelligence+reports regression: `36 passed`
- Backend full regression suite (offline/sync + API/unit): `56 passed` (latest full-pass result recorded in progress tracker)
- Command examples:
```bash
cd /Users/laxmankc/Startup/SME/sme-digital/backend
uv run pytest -q
```

## 4. Mobile Strategy (Flutter)

### 4.1 Unit tests

- Sale total and payment split calculation.
- Input validation (login/signup/sale forms).
- Provider state transitions: loading/success/failure.

### 4.2 Widget tests

- Login/signup screens validation and error display.
- Dashboard cards with realistic data states.
- Product list rendering/contrast regressions.
- Ledger and stock history list rendering.

### 4.3 Integration tests

- Login -> create sale -> verify dashboard refresh.
- Credit sale -> payment -> ledger reflects running balance.
- Refund flow updates stock and summaries.
- Offline queue -> reconnect -> sync completion without duplicates.
- Sync cursor pagination + ACK reconciliation + retry/failure states.
- Intelligence/Risk UI/provider refresh and offline-cache fallback.

### 4.4 Current mobile automated status (latest verified)

- Intelligence/Risk UI tests: passing
- Intelligence providers refresh/fallback tests: passing
- SyncService integration tests (ACK/cursor/chunk/cache overwrite): passing
- Sync coordinator integration tests (reconnect/backoff/invalidation): passing
- `flutter analyze`: clean on touched offline/intelligence surfaces

## 5. Manual E2E Scenarios (Release Gate)

1. Register user and create store.
2. Add products and customers.
3. Create cash, credit, and mixed sales.
4. Post customer payment.
5. Execute partial refund.
6. Verify stock history and customer ledger.
7. Verify summary/cashbook/top-products reports.
8. Simulate offline transaction and sync recovery.
9. Verify export output contains all domains.

All 9 scenarios must pass before production promotion.

## 6. Non-functional checks

- Performance: sale entry and save under low-end device conditions.
- Reliability: no crash across repeated sync retries.
- Security: revoked refresh token cannot be reused.

## 7. Exit Criteria (v1 Core)

- Backend tests green.
- No blocker defects in manual E2E.
- No data-integrity bug (stock, credit, refund, ledger).
- Mobile error states visible and actionable (loading/success/failure).

## 8. Known Remaining Hardening (Post-v1)

- Full end-to-end automated device/network chaos tests
- Periodic manual rollout checklist runs for release candidates
- Feature-flagged rollout path for intelligence/risk layer (optional operational control)
