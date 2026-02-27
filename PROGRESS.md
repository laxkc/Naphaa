# SME Digital Progress (Clean Tracker)

Last updated: 2026-02-27

## Project Snapshot

Status: `Active`

Current state:
- Offline-first core is implemented (`mobile local-first + sync`, backend sync hardening)
- Intelligence/Risk Layer (`IR0`-`IR8`) is complete (`v1 core`)
- Billing + PDF + i18n (mobile-only) (`BP0`-`BP9`) is complete (`v1 core`)
- Broad mobile UI localization pass is largely complete (user-facing screens localized with migration helper)
- Calendar architecture refactor planning started (`CAL0`)

Important note:
- This file is intentionally concise.
- Detailed implementation history was removed from here to keep this tracker usable day-to-day.
- Source of detailed truth remains: git history + docs in `/Users/laxmankc/Startup/SME/sme-digital/docs`

## Calendar Refactor Plan (BS Default, AD Safe Core)

Status: `🟡 Planned`
Audit basis:
- backend + mobile calendar/date audit completed
- target rule set confirmed: `AD-only storage`, `BS default UI`, `BusinessDate != EventTimestamp`

### Target Rules (Non-Negotiable)

- [ ] Storage remains AD only across backend DB, mobile DB, sync payloads, exports
- [ ] Business/accounting dates become explicit `*_date_ad` fields (`YYYY-MM-DD`)
- [ ] Event/audit/sync timestamps become explicit UTC `*_at_utc` fields (`RFC3339 Z`)
- [ ] BS is presentation/input only, never grouping/filtering/storage authority
- [ ] Default calendar mode becomes `BS`, with per-business switch to `AD`
- [ ] All reporting buckets use business timezone + AD business date, never raw `created_at`

### Phase CAL0 — Freeze Architecture + Inventory

- [x] Inventory backend/mobile/API/PDF/sync date fields
- [x] Classify fields into `BusinessDate`, `EventTimestamp`, `FiscalBoundary`, `AuditDate`, `DerivedDate`, `DisplayOnlyDate`
- [x] Identify current danger zones (`DateTime.now()`, naive ISO strings, timestamp-based reporting, fake BS year numbering)
- [ ] Publish final implementation spec doc from audit
- [ ] Acceptance: architecture is frozen before schema changes start

### Phase CAL1 — Server Schema Refactor

- [ ] Add `stores.business_timezone` with default `Asia/Kathmandu`
- [ ] Add explicit business date columns:
- [ ] `sales.sale_date_ad`
- [ ] `expenses.expense_date_ad`
- [ ] `customer_payments.payment_date_ad`
- [ ] `sale_refunds.refund_date_ad`
- [ ] Standardize canonical event timestamps as UTC-only semantics on server models/API
- [ ] Tighten DTO typing so date fields are real `date`/`datetime`, not free-form strings where avoidable
- [ ] Acceptance: backend can persist business dates independently from timestamps

### Phase CAL2 — Mobile Schema Refactor

- [ ] Add local business date columns mirroring backend:
- [ ] `sales.sale_date_ad`
- [ ] `expenses.expense_date_ad`
- [ ] `customer_payments.payment_date_ad`
- [ ] `sale_refunds.refund_date_ad`
- [ ] `invoices.issue_date_ad`
- [ ] `invoices.due_date_ad`
- [ ] Standardize local event timestamps to UTC string fields (`*_at_utc`)
- [ ] Remove ongoing reliance on naive local ISO timestamps for new writes
- [ ] Acceptance: local DB can support offline-safe accounting dates

### Phase CAL3 — Historical Backfill + Compatibility

- [ ] Backfill server business dates from legacy timestamps using business timezone
- [ ] Backfill mobile business dates from legacy timestamps using business timezone
- [ ] Keep compatibility read path during migration window
- [ ] Add one-time migration diagnostics for malformed/naive legacy timestamps
- [ ] Acceptance: old data remains usable and lands in deterministic accounting buckets

### Phase CAL4 — BusinessClock Service

- [ ] Introduce centralized `BusinessClock` on mobile
- [ ] Add `nowUtc()`
- [ ] Add `currentBusinessDate()`
- [ ] Add `startOfDayAd()` / `endOfDayAd()`
- [ ] Route all `today / this week / this month` logic through `BusinessClock`
- [ ] Remove direct feature-level `DateTime.now()` usage in reports/dashboard/accounting filters
- [ ] Acceptance: all period logic is business-timezone aware and deterministic

### Phase CAL5 — CalendarAdapter Layer

- [ ] Introduce single calendar adapter service (`BS <-> AD`)
- [ ] Hide third-party Nepali date library behind adapter boundary
- [ ] Support:
- [ ] `bsToAdDate`
- [ ] `adToBsDate`
- [ ] `formatBusinessDate`
- [ ] `formatFiscalYearLabel`
- [ ] Acceptance: UI/PDF/forms never talk to calendar library directly

### Phase CAL6 — Settings + Default BS UX

- [ ] Add persisted `calendar_mode` per business/profile with default `BS`
- [ ] Load calendar mode from source of truth (`backend store/profile`, then local cache)
- [ ] Switch UI date display based on business setting, not device locale alone
- [ ] Add BS/AD-aware date input strategy for forms
- [ ] Acceptance: fresh business sees BS by default; AD remains selectable without data model change

### Phase CAL7 — Reporting Refactor

- [ ] Refactor backend report queries to use explicit business date columns
- [ ] Refactor mobile local reports to use `*_date_ad`, not `created_at`
- [ ] Refactor dashboard summaries, sales reports, profit reports, credit aging, business health
- [ ] Ensure server and offline reports bucket identically
- [ ] Acceptance: accounting/report totals are stable across timezone changes and sync boundaries

### Phase CAL8 — Billing / Overdue / Numbering

- [ ] Replace invoice business date usage with `issue_date_ad` / `due_date_ad`
- [ ] Refactor overdue logic to compare against `currentBusinessDate()`
- [ ] Fix invoice numbering:
- [ ] AD mode -> AD year
- [ ] BS mode -> real BS year from adapter
- [ ] Refactor invoice PDF/date labels through calendar formatting service
- [ ] Acceptance: invoice dates/numbering are correct in BS mode without corrupting storage

### Phase CAL9 — Sync Contract Hardening

- [ ] Reject naive timestamps in sync/API boundary
- [ ] Require UTC `Z` timestamps for event fields
- [ ] Treat business dates as immutable accounting fields during sync
- [ ] Ensure conflict handling never silently rewrites accounting dates from formatted/local display values
- [ ] Acceptance: offline-first sync cannot corrupt accounting day buckets

### Phase CAL10 — Testing and Rollout

- [ ] Golden BS↔AD round-trip tests
- [ ] Month-end / fiscal-year / overdue boundary tests
- [ ] Offline create -> reconnect sync consistency tests
- [ ] Device timezone change regression tests
- [ ] Server vs local report parity tests
- [ ] Library version pin + upgrade policy for Nepali calendar dependency
- [ ] Acceptance: calendar support is enterprise-safe before rollout

### Delivery Order

- [ ] Step 1: `CAL0 -> CAL1 -> CAL2`
- [ ] Step 2: `CAL3 -> CAL4 -> CAL5`
- [ ] Step 3: `CAL6 -> CAL7`
- [ ] Step 4: `CAL8 -> CAL9`
- [ ] Step 5: `CAL10` + rollout checklist

