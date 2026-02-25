# i18n Migration Tracker (Full App)

Last updated: 2026-02-25

Purpose:
- Track the migration from inline bilingual strings (`context.tr(...)`) to production ARB key-based localization (`AppLocalizations`)
- Keep implementation status visible by feature/screen without bloating `PROGRESS.md`

References:
- Strategy/spec: `/Users/laxmankc/Startup/SME/sme-digital/docs/i18n-migration-plan.md`
- Clean tracker: `/Users/laxmankc/Startup/SME/sme-digital/PROGRESS.md`

## Status Legend

- `⚪ Not Started` = still using raw strings or not reviewed
- `🟡 Bridge` = localized with `context.tr(...)` (temporary migration bridge)
- `🟢 ARB Migrated` = uses `AppLocalizations` keys (target state)
- `🔵 Mixed` = partial ARB migration; some bridge strings remain

## Migration Phases (Execution)

- `I18N-0` Conventions + tracker + guardrails
- `I18N-1` Shared/common UI strings
- `I18N-2` Core operations (`dashboard`, `sales`, `customers`, `products`, `expenses`)
- `I18N-3` Reports + Intelligence + Billing (+ PDF labels)
- `I18N-4` Settings/Auth/Onboarding/Admin
- `I18N-5` Cleanup + CI enforcement + bridge removal

## Cross-Cutting Tasks

| Item | Status | Notes |
|---|---|---|
| Key naming convention (`feature.section.label`) | `⚪ Not Started` | Define examples + do/don'ts in implementation kickoff |
| ARB file structure (`app_en.arb`, `app_ne.arb`) | `⚪ Not Started` | Confirm grouping and placeholder style |
| Enum/status label localization helpers | `🟡 Bridge` | Initial shared helper added (`display_labels.dart`) using migration bridge; migrate helper internals to ARB keys later |
| Dynamic strings (placeholders/plurals) policy | `⚪ Not Started` | Counts, dates, warnings, search results |
| PDF label localization alignment | `⚪ Not Started` | Billing PDF labels should share keys/policy |
| CI guardrails for migrated files | `⚪ Not Started` | Block new `context.tr(...)` in migrated files |
| Translation ownership workflow | `⚪ Not Started` | Dev/Product/Translator/QA handoff |

## Feature / Screen Tracker

### Shared / Core UI

| Area | File / Scope | Status | Phase | Notes |
|---|---|---|---|---|
| Shared common widgets | `mobile/lib/shared/widgets/*` | `🟢 ARB Migrated` | `I18N-1` | `ui_kit` ErrorRetry + ConfirmDialog defaults moved to ARB; shared common UI slice completed for current set |
| App-level sync/status banners | `mobile/lib/shared/widgets/app_shell.dart` | `🟢 ARB Migrated` | `I18N-1` | Sync/status banner + app shell labels + telemetry summary migrated to ARB placeholders |
| Localization bridge helper | `mobile/lib/core/l10n/context_i18n.dart` | `🟡 Bridge (unused)` | `I18N-5` | Retained temporarily for compatibility; `mobile/lib` no longer references `context.tr(...)` |

### Auth / Onboarding / Profile / Settings

| Area | File / Scope | Status | Phase | Notes |
|---|---|---|---|---|
| Auth landing | `mobile/lib/features/auth/presentation/landing_page.dart` | `🟢 ARB Migrated` | `I18N-4` | Landing hero copy, feature bullets, and CTA labels migrated to ARB |
| Auth screen | `mobile/lib/features/auth/presentation/auth_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | Remaining raw auth labels (`Back`, brand subtitle) migrated to ARB |
| Forgot password | `mobile/lib/features/auth/presentation/forgot_password_page.dart` | `🟢 ARB Migrated` | `I18N-4` | Titles/body/success banner/actions migrated to ARB |
| Onboarding | `mobile/lib/features/onboarding/presentation/onboarding_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | Setup flow titles, step/count placeholders, options, tax/unit labels migrated to ARB |
| Profile | `mobile/lib/features/profile/presentation/profile_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | Role/store field labels and sign-out dialog migrated to ARB |
| Settings main | `mobile/lib/features/settings/presentation/settings_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | Section headers, tiles, sign-out dialog migrated to ARB |
| Business settings | `mobile/lib/features/settings/presentation/business_settings_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | API-backed form labels/chips/save messages migrated to ARB |
| Tax settings | `mobile/lib/features/settings/presentation/tax_settings_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | VAT/PAN form labels, save actions, errors migrated to ARB |
| Subscription | `mobile/lib/features/settings/presentation/subscription_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | Plan card, feature list, upgrade CTA migrated to ARB |
| User management | `mobile/lib/features/settings/presentation/user_management_screen.dart` | `🟢 ARB Migrated` | `I18N-4` | Owner/staff labels and invite dialog/messages migrated to ARB |

### Dashboard / Operations (Core)

| Area | File / Scope | Status | Phase | Notes |
|---|---|---|---|---|
| Dashboard | `mobile/lib/features/dashboard/presentation/dashboard_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Alerts bell states, low-stock card labels, quick actions, and dashboard error state migrated to ARB |
| Sales shell/tab | `mobile/lib/features/sales/presentation/sales_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Quick-add dialogs, risk warning, empty/search states, cart summary labels migrated to ARB placeholders |
| Sales list | `mobile/lib/features/sales/presentation/sales_list_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | App bar, filters, empty states, quick action label, walk-in fallback migrated to ARB |
| Create sale | `mobile/lib/features/sales/presentation/create_sale_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | App bar, quick-add dialogs, risk warning, empty/search states, stock/cart labels migrated to ARB placeholders |
| Sale detail | `mobile/lib/features/sales/presentation/sale_detail_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Titles, labels, totals, item/payment rows migrated to ARB; payment labels use shared display helper |
| Credit payment | `mobile/lib/features/sales/presentation/credit_payment_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Payment form labels, validation, success/error messages, method labels migrated to ARB/shared helper |
| Customers list | `mobile/lib/features/customers/presentation/customers_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Search, empty/error states, delete dialog, debt labels, payment tooltip migrated to ARB; risk badge uses shared display helper |
| Customer form | `mobile/lib/features/customers/presentation/customer_form_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Titles, labels, validation, save/error messages migrated to ARB |
| Customer detail | `mobile/lib/features/customers/presentation/customer_detail_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Titles, transaction history, payment labels, risk explanation panel, severity/day placeholders migrated to ARB |
| Products list | `mobile/lib/features/products/presentation/products_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Search, errors/empty state, delete dialog, low-stock badge, stock/price labels, adjust-stock tooltip migrated to ARB |
| Product form | `mobile/lib/features/products/presentation/product_form_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Titles, labels, hints, validation, save/error messages migrated to ARB |
| Product detail | `mobile/lib/features/products/presentation/product_detail_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Detail titles, metric labels, stock-history labels, empty state, adjust-stock CTA migrated to ARB |
| Stock adjustment | `mobile/lib/features/products/presentation/stock_adjustment_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Titles, labels, quantity/reason/note strings, validation and save error messages migrated to ARB |
| Expenses | `mobile/lib/features/expenses/presentation/expenses_screen.dart` | `🟢 ARB Migrated` | `I18N-2` | Category labels, list errors/empty state, form labels/validation/save error migrated to ARB |

### Reports / Intelligence / Sync Diagnostics

| Area | File / Scope | Status | Phase | Notes |
|---|---|---|---|---|
| Reports home | `mobile/lib/features/reports/presentation/reports_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Quick stats + report tiles (titles/subtitles) migrated to ARB |
| Sales report | `mobile/lib/features/reports/presentation/sales_report_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Title, period filters, summary/breakdown labels, and transaction-count placeholder migrated to ARB |
| Profit report | `mobile/lib/features/reports/presentation/profit_report_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Title, period filters, breakdown labels, and estimated-profit notice migrated to ARB |
| Credit report | `mobile/lib/features/reports/presentation/credit_report_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Title, empty state, summary labels/count placeholder, and risk badge placeholder migrated to ARB |
| Credit aging report | `mobile/lib/features/reports/presentation/credit_aging_report_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Filters, summary, bucket labels, cached-data banner, customer-card labels, and placeholders migrated to ARB |
| Alerts feed | `mobile/lib/features/reports/presentation/alerts_feed_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Title, mark-read actions, and empty-state labels migrated to ARB |
| Business Health | `mobile/lib/features/reports/presentation/business_health_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Cached banner, summary sections, cash outlook, risk/stock/alerts/fast-movers labels and placeholders migrated to ARB |
| Product Insights | `mobile/lib/features/reports/presentation/product_insights_report_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Filters, empty/cached states, summary labels, profit/fast-mover/dead-stock sections and line labels migrated to ARB |
| Ledger report | `mobile/lib/features/reports/presentation/ledger_report_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Title and empty state labels migrated to ARB |
| Sync Diagnostics | `mobile/lib/features/sync/presentation/sync_queue_screen.dart` | `🔵 Mixed` | `I18N-4` | Major labels/actions moved to ARB; raw row status strings still pending helper/ARB cleanup |

### Billing (UI + PDF)

| Area | File / Scope | Status | Phase | Notes |
|---|---|---|---|---|
| Invoice list | `mobile/lib/features/billing/presentation/invoice_list_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | App bar/FAB, empty state, draft labels, totals summary placeholders migrated to ARB; invoice status label still uses shared display helper |
| Invoice create | `mobile/lib/features/billing/presentation/invoice_create_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Form labels, actions, validation, and line-item editor labels migrated to ARB |
| Invoice detail | `mobile/lib/features/billing/presentation/invoice_detail_screen.dart` | `🟢 ARB Migrated` | `I18N-3` | Invoice summary/items/payments/actions and payment dialog labels/messages migrated to ARB; enum labels still via shared display helper |
| Invoice PDF labels | `mobile/lib/features/billing/data/invoice_pdf_service.dart` | `🟢 ARB Migrated` | `I18N-3` | PDF labels now use key-based localization lookup (`lookupAppLocalizations`) with invoice/business language snapshot |

## Migration Batches (Recommended Order)

### Batch A (First ARB migration)
- Dashboard
- Sales (`sales_screen`, `sales_list_screen`, `create_sale_screen`, `sale_detail_screen`)
- Customers (`customers_screen`, `customer_form_screen`, `customer_detail_screen`)

Goal:
- Prove ARB workflow on highest-traffic screens
- Introduce enum/status display helpers and placeholder patterns

### Batch B
- Products
- Expenses
- Shared/common widgets

### Batch C
- Reports + Intelligence + Sync Diagnostics

### Batch D
- Billing screens + PDF labels

### Batch E
- Settings / Auth / Onboarding / Profile / admin/support screens

### Batch F (Cleanup)
- Remove bridge usage from migrated files
- Turn on CI guardrails

## Guardrail Checklist (Enable During Migration)

- [ ] `gen_l10n` generation succeeds in CI
- [ ] `en` and `ne` ARB files are present and complete for migrated screens
- [ ] Placeholder names/types match across locales
- [ ] No new `context.tr(...)` calls in ARB-migrated files
- [ ] Widget smoke tests for at least one EN and one NE screen per batch
- [ ] PDF Nepali font rendering tested for billing batch

## Notes / Operating Rules

- Do not block feature delivery with a big-bang i18n rewrite
- Migrate by batch and mark status changes here
- `context.tr(...)` is allowed only in non-migrated (`⚪` / `🟡`) files
- When a file becomes `🟢 ARB Migrated`, do not add new inline bilingual strings to it
