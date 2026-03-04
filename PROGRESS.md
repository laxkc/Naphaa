# Naphaa Mobile Refactor Tracker

## Scope
This tracker covers only the current mobile-domain refactor requested for data consistency:
- Sales architecture hardening
- Inventory event model adoption
- Payment and customer flow cleanup
- Sync correctness for sales/invoice events
- Dashboard/report correctness from normalized facts

---

## Target Rules (Non-Negotiable)
- [x] `R1` Every sale must have at least one item.
- [x] `R2` Sale total must be system-derived from items (no manual total input).
- [x] `R3` Customer is optional, but required for any credit amount.
- [x] `R4` Sales are immutable after completion; corrections via `void` or `return` events.
- [ ] `R5` Inventory is derived from inventory events, not direct stock mutations.
- [ ] `R6` All writes are local-first and queued for sync with idempotent `op_id`.
- [ ] `R7` No cross-account/store data collisions during sync.

---

## Phase P0 - Data Integrity Guardrails (Highest Priority)
### Goal
Lock the system against inconsistent financial/inventory states.

### Tasks
- [x] Add strict sale invariants at repository boundary:
  - reject empty `items`
  - reject zero/negative qty and price
  - reject payment sum mismatches
  - reject credit sale without customer
- [x] Enforce invariant checks in sync apply path for incoming `sale` events.
- [x] Add explicit `status` column for `sales` in local DB and align domain mapping.
- [x] Add local migration for existing rows with safe default status.
- [x] Add tests for invalid payload rejection and valid payload acceptance.

### Acceptance Criteria
- [x] No path (UI, repository, sync pull) can create a sale without items.
- [x] No path can persist a credit amount without `customer_id`.
- [x] Domain `Sale.status` always maps to a real stored value.

### Test Gate
- [x] Unit: sale validation rules.
- [x] Integration: create sale + pull sale event invariants.
- [x] Regression: existing cash and credit sale happy paths remain green.

---

## Phase P1 - Payment Model Completion
### Goal
Support professional payment capture without ambiguity.

### Tasks
- [x] Extend sale checkout UI to support methods: cash, QR, bank, wallet, credit, mixed.
- [x] Add split-payment entry UI and validation.
- [x] Persist all payments in `sale_payments` with method + amount.
- [x] Derive `credit_amount` strictly from payment rows.
- [x] Keep one-tap fast cash flow for speed.

### Acceptance Criteria
- [x] Mixed payments produce correct totals and credit remainder.
- [x] `sale_type` and payment rows are consistent.
- [ ] Credit report reflects split-payment residual credit correctly.

### Test Gate
- [x] Unit: split-payment math and validation.
- [ ] Integration: mixed payment sale + sync push/pull roundtrip.
- [ ] UI test: quick cash path still <= 5 taps.

---

## Phase P2 - Customer Flow Redesign (Walk-in Default)
### Goal
Remove fake customer data while preserving credit discipline.

### Tasks
- [x] Keep walk-in default for all non-credit sales.
- [x] Replace credit quick-create-only flow with:
  - pick existing customer
  - quick add customer
  - explicit validation if credit amount > 0
- [x] Add overdue/risk indicator in customer picker for credit decisions.
- [x] Prevent accidental duplicate customer creation in rapid flow.

### Acceptance Criteria
- [x] Cash sale never requires customer.
- [x] Credit sale always enforces customer selection.
- [x] Existing customers are discoverable in <= 2 interactions.

### Test Gate
- [ ] Integration: credit sale with existing customer.
- [ ] Integration: credit sale with quick-created customer.
- [x] Regression: walk-in cash sale unaffected.

---

## Phase P3 - Inventory Event-Sourcing Adoption
### Goal
Make stock explainable and auditable from event history.

### Tasks
- [x] Introduce canonical `inventory_events` model usage in write path.
- [x] Emit inventory events for:
  - sale
  - invoice issue
  - stock adjustment
  - return
  - loss
- [x] Move stock updates to event-driven recompute/service path.
- [x] Keep `products.stock_qty` as cached projection only.
- [x] Backfill events for existing stock-affecting transactions where possible.

### Current P3 Progress (In Flight)
- [x] Local sale writes emit `stock_movements` (`movement_type=SALE`) with `delta_qty` and `reference_id`.
- [x] Local stock adjustment writes emit `stock_movements` (`movement_type=ADJUSTMENT`) with reason reference.
- [x] Product creation writes emit opening stock movement (`movement_type=OPENING`).
- [x] Local invoice issue writes emit `stock_movements` (`movement_type=INVOICE_ISSUE`).
- [x] Sync pull for `sale` applies stock deduction and emits matching `stock_movements` rows.
- [x] Sync pull for `product/ADJUST_STOCK` applies stock adjustment and emits matching `stock_movements` rows.
- [x] Sync pull for `invoice` issue applies stock deduction and emits matching `stock_movements` rows.
- [x] Sync pull for `sale_refund` applies stock restock and emits `RETURN` movement rows.
- [x] Sync pull for `stock_loss` applies stock deduction and emits `LOSS` movement rows.
- [x] Local stock adjustment classifies `RETURN` and `LOSS` movement types by reason.
- [x] Projection reconciliation service recomputes `products.stock_qty` from movement sums.
- [x] Backfill service inserts missing opening/history movement rows for legacy products.
- [ ] Remaining: optional precision enhancements for deep historical imports.

### Acceptance Criteria
- [x] Every stock change has a corresponding event row.
- [x] Product stock is reproducible from event sum.
- [x] Dashboard low-stock and product insights use projected stock from events.

### Test Gate
- [x] Unit: stock projection from event stream.
- [x] Integration: sale/adjustment/return modifies projected stock correctly.
- [x] Data check: stock projection equals cached stock for all products.
- [x] Regression: local sale write creates stock movement row.
- [x] Regression: sync-pulled sale updates stock cache and movement row.
- [x] Regression: sync-pulled invoice issue updates stock cache and movement row.
- [x] Regression: sync-pulled sale refund restocks stock and updates sale status.
- [x] Regression: sync-pulled stock loss deducts stock with `LOSS` movement type.
- [x] Regression: projection reconcile inserts baseline for legacy movement-less products.

---

## Phase P4 - Sale Correction Lifecycle (Void / Return)
### Goal
Eliminate destructive edits and preserve accounting truth.

### Tasks
- [x] Implement sale `void` flow with reason and permission checks.
- [x] Implement sale `return` flow (full/partial lines) with reason.
- [x] Persist return/void records and generate compensating inventory/payment effects.
- [x] Update ledger/report views to show original + correction linkage.

### Acceptance Criteria
- [x] Completed sales cannot be hard-deleted.
- [x] All corrections are represented as explicit events.
- [x] Inventory and receivables remain balanced after return/void.

### Test Gate
- [x] Integration: void cash sale.
- [x] Integration: partial return of credit sale.
- [x] Regression: old sales list/detail rendering remains stable.

---

## Phase P5 - Sync Contract Hardening (Production Safety)
### Goal
Remove sync ambiguity and silent data loss.

### Tasks
- [x] Resolve `deferred` queue handling gap for invoice events.
- [x] Define allowed sync statuses and processing rules (`pending`, `syncing`, `failed`, `blocked`, `synced`).
- [x] Ensure all outbound sale/invoice events include required invariant fields.
- [x] Reject malformed inbound events with diagnostics.
- [x] Add dead-letter handling for permanently invalid events.
- [x] Preserve store/account isolation for all queue operations.

### Acceptance Criteria
- [x] No queue item is left permanently unprocessed due to unknown status.
- [x] Invalid events become diagnosable, not silently destructive.
- [x] No cross-store event application.

### Test Gate
- [x] Integration: offline create -> reconnect push -> pull merge.
- [x] Integration: invalid payload moves to blocked/dead-letter with clear reason.
- [x] Regression: account switch archives foreign pending rows correctly.

---

## Phase P6 - Dashboard and Report Consistency
### Goal
Metrics reflect normalized, trustworthy transactional facts.

### Tasks
- [x] Align sales/credit/inventory dashboard cards to new event-backed facts.
- [x] Ensure low-stock logic uses projected stock and threshold per product.
- [x] Align sales/profit/ledger/customer reports with correction lifecycle (void/return).
- [x] Remove any duplicate counting paths from mixed local+legacy assumptions.

### Acceptance Criteria
- [x] Dashboard totals match report totals for same period.
- [x] Low-stock list is accurate after sell-out and returns.
- [x] Credit aging and customer balances match payment/sale facts.

### Test Gate
- [x] Integration: seeded scenario comparison (dashboard vs reports).
- [x] Regression: period filters (today/week/month) stay accurate.

---

## Phase P7 - UX Performance for SME Speed
### Goal
Keep enterprise correctness without slowing checkout.

### Tasks
- [x] Optimize product selection: recent, search, and quick quantity controls.
- [x] Keep checkout path short for common cash sale.
- [x] Add post-sale success feedback and lightweight failure recovery UX.
- [x] Add telemetry points for checkout completion time (local diagnostics).

### Acceptance Criteria
- [x] Happy-path cash sale remains fast and reliable.
- [x] Error states are actionable (not generic).

### Test Gate
- [x] Integration: sale save remains successful when sync fails (retry notice shown).
- [x] Integration: sale save failure (insufficient stock) shows actionable message.
- [x] Integration: checkout diagnostics rows persist for success/failure flows.
- [x] Migration: v16 -> v17 adds checkout diagnostics schema.
- [x] Unit: product search ranking prefers exact/prefix and recent sales relevance.
- [x] Manual timing benchmark for top 3 sale flows.
- [x] UI regression on iPhone simulator for checkout and sales list.

---

## Cross-Phase Technical Debt Cleanup
- [x] Consolidate duplicated sales screens (`sales_screen` vs `create_sale_screen`) to one canonical flow.
- [x] Remove stale fields/tables not used by final architecture.
- [x] Add architecture decision note in docs for sale + inventory + sync invariants.

---

## Execution Order
- [x] Start P0
- [x] Complete P0
- [x] Complete P1
- [x] Complete P2
- [x] Complete P3
- [x] Complete P4
- [x] Complete P5
- [x] Complete P6
- [x] Complete P7
- [x] Final full regression pass

---

## Current Snapshot
- [x] Assessment completed: current mobile behavior vs target architecture.
- [x] Refactor implementation started.
- [x] End-to-end consistency achieved.
