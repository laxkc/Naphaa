# Calendar Architecture Refactor

Last updated: 2026-02-27
Status: `CAL0`

## Objective

Refactor Naphaa calendar handling to support:

- default `BS` UI mode
- optional `AD` UI mode
- AD-only storage
- offline-first correctness
- deterministic accounting/reporting

This document is the implementation lock for calendar work. Feature code should not start before the rules and schema direction here are accepted.

## Locked Rules

### 1. Canonical storage

- All storage remains AD only.
- All business/accounting dates are stored as explicit `*_date_ad` fields.
- All event/audit/sync timestamps are stored as UTC `*_at_utc` fields.
- BS never becomes a grouping key, DB storage value, or sync authority.

### 2. Domain split

#### BusinessDate

Date only. No time component.

Examples:

- `sale_date_ad`
- `expense_date_ad`
- `payment_date_ad`
- `refund_date_ad`
- `issue_date_ad`
- `due_date_ad`

Format:

- `YYYY-MM-DD`

#### EventTimestamp

UTC timestamp only.

Examples:

- `created_at_utc`
- `updated_at_utc`
- `deleted_at_utc`
- `synced_at_utc`
- `computed_at_utc`

Format:

- RFC3339 UTC with `Z`

### 3. Timezone rule

- Business timezone is explicit per store.
- Initial default: `Asia/Kathmandu`
- Business dates are derived from business timezone, not device timezone.
- `DateTime.now()` must not be used directly for accounting/reporting buckets.

### 4. API contract rule

- API accepts AD only.
- `BusinessDate` values use `YYYY-MM-DD`
- `EventTimestamp` values use RFC3339 UTC
- Naive timestamps are rejected.

## Current Danger Zones To Replace

These are the concrete patterns the refactor removes.

### Mobile reporting uses device-local now

Files:

- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/reports/presentation/sales_report_screen.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/reports/presentation/profit_report_screen.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/sales/presentation/sales_list_screen.dart`

Problem:

- today/week/month are built from `DateTime.now()`
- bucket boundaries depend on device timezone

Target:

- all period boundaries come from `BusinessClock`

### Accounting flows use timestamps instead of business dates

Files:

- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/sales/data/sales_repository.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/expenses/data/expenses_repository.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/customers/data/customers_repository.dart`

Problem:

- sales, expenses, and payments are written with `created_at`
- reports later derive accounting day from timestamp

Target:

- write `*_date_ad` at mutation time
- keep UTC event timestamp separately

### Billing dates are mis-modeled as datetimes

Files:

- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/billing/data/billing_repository.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/billing/domain/invoice_models.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/features/billing/data/invoice_numbering_service.dart`

Problem:

- `issue_date` and `due_date` are datetime-like values
- overdue logic compares datetimes
- BS numbering uses AD year placeholder

Target:

- `issue_date_ad`
- `due_date_ad`
- overdue compares `BusinessDate`
- BS invoice year comes from calendar adapter only

### Sync mixes naive local timestamps with server UTC semantics

Files:

- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/core/network/sync_service.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/core/sync/sync_queue.dart`
- `/Users/laxmankc/Startup/SME/sme-digital/backend/app/services/sync_service.py`

Problem:

- mobile writes local ISO strings
- backend conflict code coerces naive payloads

Target:

- only UTC `Z` timestamps cross sync boundary
- business dates are separate and immutable accounting values

## Required Schema Changes

## Server

### Add to `stores`

- `business_timezone TEXT NOT NULL DEFAULT 'Asia/Kathmandu'`
- `calendar_mode TEXT NOT NULL DEFAULT 'BS'`

### Add business dates

#### `sales`

- `sale_date_ad DATE NOT NULL`

#### `expenses`

- `expense_date_ad DATE NOT NULL`

#### `customer_payments`

- `payment_date_ad DATE NOT NULL`

#### `sale_refunds`

- `refund_date_ad DATE NOT NULL`

### Timestamp standardization

Keep current columns for compatibility if needed, but logical meaning becomes:

- `created_at` => UTC event timestamp
- `updated_at` => UTC event timestamp
- `deleted_at` => UTC event timestamp

If later renamed, rename to explicit `_utc` names in a dedicated cleanup phase.

## Mobile local DB

### Add to local tables

#### `sales`

- `sale_date_ad TEXT NOT NULL`

#### `expenses`

- `expense_date_ad TEXT NOT NULL`

#### `customer_payments`

- `payment_date_ad TEXT NOT NULL`

#### `sale_refunds`

- `refund_date_ad TEXT NOT NULL`

#### `invoices`

- `issue_date_ad TEXT`
- `due_date_ad TEXT`

### Local timestamp semantics

All new timestamp writes must be UTC RFC3339 values.

Examples:

- `created_at`
- `updated_at`
- `paid_at`
- `computed_at`

If column rename is deferred, semantics still change first. Naming cleanup can follow after rollout.

## Backfill Strategy

Assumption for historical Naphaa data:

- historical records are interpreted in `Asia/Kathmandu`

Backfill rule:

- `*_date_ad = local_date(created_at, business_timezone)`

Examples:

- `sale_date_ad = created_at -> Asia/Kathmandu -> YYYY-MM-DD`
- `expense_date_ad = created_at -> Asia/Kathmandu -> YYYY-MM-DD`

Important:

- Existing naive local mobile timestamps are not globally trustworthy.
- For current Naphaa scope, Nepal timezone assumption is acceptable.
- If multi-country rollout happens later, this migration logic must become store-specific.

## Service Layer Changes

## `BusinessClock`

Single source for:

- `nowUtc()`
- `currentBusinessDate()`
- `startOfDayAd(date)`
- `endOfDayAd(date)`
- `currentWeekRangeAd()`
- `currentMonthRangeAd()`

Consumers:

- dashboard
- sales filters
- reports
- overdue logic
- local metrics

## `CalendarAdapter`

Wrap the Nepali date dependency behind one adapter.

Required methods:

- `bsToAdDate()`
- `adToBsDate()`
- `formatBusinessDate()`
- `formatDateRange()`
- `formatFiscalYearLabel()`

Rules:

- app code does not call the third-party library directly
- BS display logic must be fully centralized

## Reporting Refactor

Before:

- reports filter on `created_at`

After:

- reports filter on `*_date_ad`

Examples:

- sales report -> `sale_date_ad`
- expense report -> `expense_date_ad`
- overdue -> `due_date_ad`

This rule applies to:

- backend report queries
- mobile local report queries
- intelligence/risk calculations
- dashboard KPI cards

## Billing Refactor

### Invoice dates

Replace logical usage of:

- `issue_date`
- `due_date`

With:

- `issue_date_ad`
- `due_date_ad`

### Overdue

Rule:

- overdue if `due_date_ad < BusinessClock.currentBusinessDate()`

Never compare invoice overdue status against raw datetimes.

### Numbering

If calendar mode is `AD`:

- year key uses AD year from `issue_date_ad`

If calendar mode is `BS`:

- year key uses BS year derived from `CalendarAdapter.adToBsDate(issue_date_ad)`

Placeholder AD-year behavior for BS must be removed.

## Sync Rules

- Business dates are written once from business timezone context.
- Sync must not silently recompute business dates from timestamps.
- Sync payload timestamps must be UTC.
- API rejects naive timestamps.
- LWW may apply to master-data timestamps, not accounting day buckets.

## Rollout Order

### CAL0

- freeze spec
- list all impacted tables/files/services

### CAL1

- backend schema changes
- DTO typing cleanup

### CAL2

- mobile local schema changes
- UTC write normalization

### CAL3

- backfill migrations
- compatibility reads

### CAL4

- `BusinessClock`
- remove direct report/date `DateTime.now()` usage

### CAL5

- `CalendarAdapter`
- BS/AD formatting

### CAL6

- settings and default BS behavior

### CAL7

- report/dashboard/intelligence query refactor

### CAL8

- billing, overdue, numbering, PDF

### CAL9

- sync hardening

### CAL10

- golden tests
- offline/report parity
- timezone regression

## Test Requirements

### Golden tests

- BS -> AD -> BS round trip
- AD -> BS -> AD round trip

### Boundary tests

- midnight
- month end
- Nepali fiscal year boundary
- overdue date boundary

### Offline tests

- create sale offline
- sync later
- verify `sale_date_ad` unchanged
- verify server/local report parity

### Timezone tests

- change device timezone
- reports remain unchanged
- overdue remains unchanged

### API validation tests

- reject BS in canonical API dates
- reject naive timestamps
- accept only `YYYY-MM-DD` and RFC3339 UTC

## Immediate Next Implementations

1. backend: add `business_timezone`, `calendar_mode`, and business-date columns
2. mobile: add local business-date columns for accounting tables
3. mobile: introduce `BusinessClock` and remove report-level direct `DateTime.now()`
4. mobile: introduce `CalendarAdapter`
5. billing: replace placeholder BS invoice year logic
