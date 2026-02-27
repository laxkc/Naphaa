# SME Digital Progress (Clean Tracker)

Last updated: 2026-02-25

## Project Snapshot

Status: `Active`

Current state:
- Offline-first core is implemented (`mobile local-first + sync`, backend sync hardening)
- Intelligence/Risk Layer (`IR0`-`IR8`) is complete (`v1 core`)
- Billing + PDF + i18n (mobile-only) (`BP0`-`BP9`) is complete (`v1 core`)
- Broad mobile UI localization pass is largely complete (user-facing screens localized with migration helper)

Important note:
- This file is intentionally concise.
- Detailed implementation history was removed from here to keep this tracker usable day-to-day.
- Source of detailed truth remains: git history + docs in `/Users/laxmankc/Startup/SME/sme-digital/docs`

## Mobile Design Refactor Plan (Full)

Status: `🟡 In Progress (D0 started)`
Source design baseline: `/Users/laxmankc/Startup/SME/sme-digital/web/DESIGN.md`
Audit doc: `/Users/laxmankc/Startup/SME/sme-digital/docs/mobile-design-refactor-plan.md`

### Design Governance (Non-Negotiable)

- [ ] No inline CSS-like styling for tokenizable UI (colors, spacing, radius, typography) in feature screens
- [ ] No random hex values in feature UI; use theme tokens only
- [ ] Maximum two brand accents in app UI (Primary Navy + Accent Coral)
- [ ] No frequent logo/brand churn; branding stays stable
- [ ] Single font family system-wide
- [ ] Do not overuse gradients; only approved highlight surfaces
- [ ] Accessibility is mandatory (contrast, tap targets, readable text scale, semantics)

### Token Baseline (Mobile)

- [ ] Typography scale aligned to design doc (Display 28, Title 22, Section 18, Card 16, Body 14, Small 12, Button 14, Total 18)
- [ ] 8pt spacing grid (`4/8/16/24/32/48`) mapped to Flutter spacing constants
- [ ] Radius scale (`6/8/12/16/pill`) mapped to Flutter radius constants
- [ ] Palette tokens aligned (bg/surface/surface-alt/border/text/semantic/focus)
- [ ] State styles defined and reused (hover/press/focus/disabled/loading)

### Phase D0 — Audit and Gap Mapping

- [x] Build full page inventory across `mobile/lib/features/*`
- [x] Capture hardcoded visual debt (inline values, random hex, inconsistent component patterns)
- [ ] Capture baseline screenshots for EN/NE on core flows
- [x] Produce priority backlog (`P0/P1/P2`) per module
- [ ] Output: audit matrix and implementation order freeze

### Phase D1 — Theme Foundation + UI Primitives

- [x] Refactor theme/token source as single source of truth
- [x] Standardize reusable primitives: `AppButton`, `AppCard`, `AppChip`, `StatusBadge`, `AppInput`, `EmptyState`, `ErrorState`
- [x] Standardize text styles and semantic color mapping
- [x] Standardize shadow/elevation/borders/radius behavior
- [ ] Output: feature pages consume shared primitives, not custom styling

### Phase D2 — App Shell and Common Layout

- [x] Align app shell, top bar, bottom nav, section paddings
- [x] Standardize loading, snackbars, dialogs, bottom sheets
- [x] Ensure route wrappers have correct Material context to prevent runtime UI assertions
- [x] Normalize safe area and keyboard behavior across all pages
- [ ] Output: consistent shell behavior and no quick-action route breakage

### Phase D3 — Auth / Onboarding / Profile

- [x] D3 started: auth screen token/radius normalization pass initiated
- [x] Auth landing, login/register, forgot password visual alignment
- [x] Onboarding visual hierarchy and spacing cleanup
- [x] Profile cards/forms aligned with shared components
- [x] Validation/error state styling standardized
- [x] Exit criteria: EN/NE text fits, no overflow, no hardcoded visual tokens

### Phase D4 — Dashboard + Quick Actions

- [x] D4 started: dashboard quick-actions responsive layout and style normalization
- [x] Dashboard cards and summaries aligned to token system
- [x] Quick action tiles standardized (icon sizes, labels, paddings, tap targets)
- [x] Fix known tile overflow edge cases
- [x] Low stock/alerts/sync indicator styling normalized
- [x] Exit criteria: all quick actions navigate correctly, no overflow

### Phase D5 — Sales

- [x] D5 started: sales list/create/detail visual standardization pass
- [x] Sales list, create sale, sale detail visual consistency
- [x] Filter chips (`Today/This week/This month`) unified
- [x] Monetary hierarchy (totals vs rows) standardized
- [x] Credit/paid/unpaid semantic badges normalized
- [x] Exit criteria: filter UX clear, no dim contrast regressions

### Phase D6 — Products / Inventory

- [x] D6 started: products/inventory style normalization pass
- [x] Product list/detail/form and stock adjustment unified
- [x] Unit/category/threshold controls standardized
- [x] Inventory status chips (low stock/dead stock) consistent
- [x] Quantity/price/value alignment and readability improved
- [x] Exit criteria: no layout regressions in add/edit/adjust flows

### Phase D7 — Customers / Credit

- [x] D7 started: customer list/detail credit visual consistency pass
- [x] Customer list search/sort/filter UI consistency
- [x] Owe/pay CTA prominence and detail summary improvements
- [x] Customer detail timeline/ledger card consistency
- [x] Long-name and large-balance rendering validation
- [x] Exit criteria: details open reliably and remain stable

### Phase D8 — Expenses

- [x] D8 started: expense summary/list professional layout pass
- [x] Expense list and item row hierarchy upgrade (professionalized layout)
- [x] Expense form sectioning and validation feedback alignment
- [x] Filter controls and empty/error states standardized
- [x] Category/amount/date emphasis with semantic clarity
- [x] Exit criteria: module quality aligned with sales/products

### Phase D9 — Reports / Intelligence / Risk

- [x] D9 started: reports filter/currency consistency pass
- [x] Sales/profit/credit/ledger report filter bar consistency
- [x] Business health/product insights/alerts UI harmonization
- [x] Risk and status colors use semantic token mapping only
- [x] Report card, chart/list section spacing normalized
- [x] Exit criteria: all report filters readable and consistent

### Phase D10 — Billing / Invoice UI

- [x] Invoice list/create/detail/payment surfaces aligned
- [x] Status badges and totals section hierarchy standardized
- [x] PDF actions (`View/Share/Print/Retry`) consistent
- [x] VAT/tax display aligned with design typography/colors
- [x] Exit criteria: billing UI consistency without breaking offline flow

### Phase D11 — Settings / Business Configuration

- [x] Business settings/profile/tax/subscription/user-management visual standardization
- [x] Form grouping and save-state feedback alignment
- [x] Account/store-scoped configuration surfaces clarified
- [x] Toggle/select/input component consistency
- [x] Exit criteria: settings UX coherent and predictable

### Phase D12 — Sync / Diagnostics UX

- [x] Sync queue and diagnostics readability improvements
- [x] Severity/status visual hierarchy standardized
- [x] Retry and error actions consistently placed/styled
- [x] Long error text rendering and truncation behavior fixed
- [x] Exit criteria: sync failures are understandable and actionable

### Cross-Cutting Tracks

- [x] X1 i18n-safe UI: no inline bilingual literals in migrated surfaces; ARB-driven labels
- [x] X2 Accessibility: contrast/tap-target/semantics checks on all refactored screens
- [x] X3 Responsive hardening: iPhone small + Android small/medium overflow checks
- [x] X4 Regression protection: add visual and widget-level checks for high-risk screens

### Testing and Quality Gates

- [ ] Visual regression snapshots (EN + NE) for core pages
- [ ] Functional regression across critical flows (auth/sales/products/customers/reports/settings/sync/billing)
- [ ] Offline-first regression (offline create -> reconnect sync -> consistency)
- [x] Accessibility smoke pass on every phase completion
- [ ] `flutter analyze` clean after each phase batch

### Delivery Order

- [x] Step 1: `D0 -> D1 -> D2` (foundation first)
- [x] Step 2: `D4 + D5` (highest daily operational impact)
- [x] Step 3: `D6 + D7`
- [x] Step 4: `D8 + D9`
- [x] Step 5: `D10 + D11 + D12`
- [x] Step 6: Final hardening across `X1/X2/X3/X4`

## Workstreams

### Offline-First Core
Status: `✅ Done (v1 core)`

Includes:
- store-scoped outbox (`sync_queue`)
- cursor-based pull + `op_id` ACKs
- reconnect/periodic sync coordinator
- backend sync projector + event emission
- sync diagnostics + user-facing sync status

Remaining hardening:
- full E2E automation (future)
- periodic manual unstable-network checklist execution

### Intelligence + Risk Layer (IR)
Status: `✅ Done (v1 core)`

Includes:
- customer risk metrics + credit aging
- alerts feed + business health
- product insights (dead stock / fast movers / profit-by-product)
- backend metrics APIs + mobile offline cache/fallback

Remaining enhancements (non-blocking):
- richer cash outlook model
- alert CTA expansion
- deeper regression coverage / rollout flags

### Billing + PDF + i18n (Mobile-Only) (BP)
Status: `✅ Done (v1 core)`

Includes:
- invoices (draft/issue/payment)
- invoice numbering
- VAT calculator
- local PDF generation/share/print
- invoice sync-ready deferred outbox events

Remaining production checks:
- manual device validation for PDF rendering/share/print (esp. Nepali font behavior)

## Production Auto-Sync Refactor Plan

Status: `🟢 Starter Scope Implemented`

### Phase S0 — Contract + Foundation (Must Keep)

- [x] Freeze sync contract: `push -> pull`, `op_id` idempotency, LWW conflict rule, cursor-based delta pull
- [x] Normalize single `sync_queue` schema (minimal): `id`, `entity`, `entity_id`, `op`, `payload`, `op_id`, `status`, `retry_count`, `next_retry_at`, `last_error`, `created_at`
- [x] Enforce transaction rule for all mutations: local DB write + queue enqueue in same transaction
- [x] Remove/forbid direct feature-level API writes for mutable operations
- [x] Acceptance: local-first integrity is guaranteed for all financial and inventory writes

### Phase S1 — Minimal Auto-Sync Engine

- [x] Add orchestrator triggers: app start, app resume, connectivity regained
- [x] Add single in-flight lock (prevent parallel sync cycles)
- [x] Implement strict cycle: push pending batch (size 20) -> mark per-row success/fail -> pull delta by cursor -> apply local
- [x] Keep manual sync button as force-sync/debug fallback
- [x] Acceptance: normal users do not need manual sync for day-to-day use

### Phase S2 — Minimal Retry + Blocked State

- [x] Add exponential backoff retry per row
- [x] Cap retries at 5 attempts
- [x] Mark exhausted/non-retriable rows as `blocked`
- [x] Keep server authoritative conflict application (no conflict UI yet)
- [x] Acceptance: no infinite retry loops; blocked rows are visible and stable

### Starter Test Matrix

- [x] Unit: queue transition + backoff cap logic
- [x] Integration: offline write -> reconnect -> push+pull success
- [x] Integration: partial push failures retry correctly
- [x] Integration: retry exhaustion transitions row to `blocked`
- [x] Integration: delta pull cursor continuity

### Deferred (Not In Starter Scope)

- [ ] Background WorkManager/BackgroundFetch scheduling
- [ ] Advanced diagnostics grouping/category dashboards
- [ ] Full telemetry/analytics pipeline
- [ ] Feature-flag rollout controls
- [ ] Advanced conflict UX / merge UI

### Starter Definition of Done (Auto-Sync)

- [x] Local-first + queue architecture enforced across app
- [x] Auto-sync works on start/resume/reconnect with in-flight lock
- [x] Push/pull delta cycle stable with idempotency
- [x] Retry policy capped; blocked rows prevent endless failures
- [x] Manual sync remains only as fallback/debug action

### Mobile Localization (Current)
Status: `🟡 In Progress (migration bridge)`

Current approach:
- `context.tr('en', 'ne')` used as migration bridge

Current coverage:
- major user-facing screens across dashboard, auth, customers, products, sales, reports, settings, sync diagnostics, billing, expenses

Next required refactor (production-scale):
- migrate to key-based ARB localization (`AppLocalizations`) and reduce/remove inline bilingual strings

Production i18n plan (full application):
- move all user-visible strings to ARB (`app_en.arb`, `app_ne.arb`)
- use key-based `AppLocalizations` in UI (`l10n.someKey`)
- keep `context.tr(...)` only as temporary migration bridge
- migrate by feature in batches: shared UI -> dashboard/sales/customers/products/expenses -> reports/intelligence/billing -> settings/auth/onboarding
- localize dynamic strings with placeholders/plurals (alerts count, item count, days, no-match query, etc.)
- localize enum/status display labels in presentation layer (payment methods, statuses, severity)
- align billing PDF labels with key-based translations
- add guardrails: missing-key checks + prevent new `context.tr(...)` in migrated files

Implementation started (production i18n foundation):
- added shared display-label mapping helper for enum/status presentation (`risk`, `payment method`, `invoice status`)
- wired initial screens to helper (customers/credit report/billing invoice screens)
- started `I18N-1` shared UI ARB migration (AppShell sync/status banner moved to ARB keys + placeholders)
- expanded `I18N-1` shared UI ARB migration (`Sync Diagnostics` major labels/actions/dialogs moved to ARB keys)
- expanded `I18N-1` shared UI ARB migration (`ui_kit` ErrorRetry defaults + app shell shared labels/telemetry moved to ARB keys)
- expanded `I18N-1` shared UI ARB migration (`showConfirmDialog` default confirm label now ARB-backed)
- completed `I18N-1` current shared/common UI slice (`ui_kit` + `AppShell` shared labels/status banners fully ARB-backed)
- started `I18N-2` core migration with Dashboard ARB slice (alerts bell states, low-stock card labels, quick actions moved to ARB; dashboard now mixed)
- advanced `I18N-2` Sales slice: `SalesListScreen` + `SaleDetailScreen` migrated to ARB/AppLocalizations (no `context.tr(...)` remaining in those files)
- advanced `I18N-2` Customers slice: `CustomersScreen` + `CustomerFormScreen` migrated to ARB/AppLocalizations (customer detail still pending)
- completed `I18N-2` Customers batch: `CustomerDetailScreen` migrated to ARB/AppLocalizations (Customers list/form/detail now ARB migrated)
- advanced `I18N-2` Products batch: `ProductsScreen` + `ProductFormScreen` + `ProductDetailScreen` migrated to ARB/AppLocalizations (`StockAdjustmentScreen` still pending)
- advanced `I18N-2` remaining core-op small screens: `CreditPaymentScreen`, `StockAdjustmentScreen`, and `ExpensesScreen` migrated to ARB/AppLocalizations
- advanced `I18N-2` Sales create/shell batch: `CreateSaleScreen` + `SalesScreen` migrated to ARB/AppLocalizations (quick-add dialogs, risk warning, empty/search states, cart labels); main remaining `I18N-2` work is Dashboard cleanup
- completed `I18N-2` Dashboard cleanup: `DashboardScreen` ARB migration finalized (dashboard error state moved to ARB); core operations batch is complete
- started `I18N-3` Reports/Intelligence/Billing migration: `ReportsScreen` (reports home) migrated to ARB/AppLocalizations (quick stats + report tiles)
- advanced `I18N-3` Reports migration: `CreditAgingReportScreen` migrated to ARB/AppLocalizations (filters, summaries, cached banner, buckets, customer labels/placeholders)
- advanced `I18N-3` Intelligence migration: `BusinessHealthScreen` migrated to ARB/AppLocalizations (cached banner, summary/cash outlook sections, risk/stock/alerts/fast-movers labels/placeholders)
- advanced `I18N-3` Alerts migration: `AlertsFeedScreen` migrated to ARB/AppLocalizations (title, mark-read actions, empty-state labels)
- advanced `I18N-3` Intelligence migration: `ProductInsightsReportScreen` migrated to ARB/AppLocalizations (filters, empty/cached states, summary/section labels, line subtitles)
- advanced `I18N-3` Billing migration: `InvoiceListScreen` migrated to ARB/AppLocalizations (app bar/FAB, empty state, draft/totals row labels/placeholders)
- advanced `I18N-3` Billing migration: `InvoiceDetailScreen` and `InvoiceCreateScreen` migrated to ARB/AppLocalizations (invoice summary/items/payments/actions, payment dialog, create form, validation, line-item editor labels)
- advanced `I18N-3` Reports migration: `SalesReportScreen`, `ProfitReportScreen`, `CreditReportScreen`, `LedgerReportScreen`, and `AlertActionRouter` message migrated to ARB/AppLocalizations
- completed `I18N-3`: Reports + Intelligence + Billing (+ PDF labels) ARB migration finished; `invoice_pdf_service.dart` now uses key-based localization lookup for PDF labels (no `context.tr(...)` in Reports/Billing scopes)
- tracker: `/Users/laxmankc/Startup/SME/sme-digital/docs/i18n-migration-tracker.md`

### UX / Polish
Status: `🟡 In Progress`

Recent UX changes:
- improved dashboard quick actions
- alert bell + unread/read behavior
- standalone quick-action routes for embedded screens
- multiple filter/contrast fixes

Remaining:
- expense screen professional polish (summary + filters + list UX)
- final consistency sweep across edge-case screens

## Active Priorities (Next)

1. Production i18n refactor implementation (`ARB key-based`, replace `context.tr(...)` gradually)
   - tracker: `/Users/laxmankc/Startup/SME/sme-digital/docs/i18n-migration-tracker.md`
   - current step: `I18N-2` Dashboard/Sales/Customers ARB migration batches
2. Expense screen professional UX refactor (summary, filtering, sync-state clarity)
3. Manual QA pass for:
   - offline/sync scenarios
   - billing PDF/share/print
   - account-switch/store isolation
4. Final release readiness regression (`backend + mobile`) before next production cut

## i18n Migration Phases (Full App)

- [x] `I18N-0` Define conventions and tracker (docs + tracker + bridge rules + foundation helper started)
- [x] `I18N-1` Shared/common UI migration (current shared slice complete; continue if new shared widgets are added)
- [x] `I18N-2` Core operations migration
- [x] `I18N-3` Reports + Intelligence + Billing migration
- [x] `I18N-4` Settings/Auth/Onboarding/Admin migration
- [x] `I18N-5` Cleanup + guardrails

- `I18N-0` Define conventions and tracker
  - key naming convention (`feature.section.label`)
  - rules for user-visible vs internal strings
  - mark `context.tr(...)` as migration-only
  - tracker doc: `/Users/laxmankc/Startup/SME/sme-digital/docs/i18n-migration-tracker.md`
  - progress: shared enum/status display helper added (bridge implementation)
- `I18N-1` Shared/common UI migration
  - dialogs, banners, empty states, common actions
  - progress: `AppShell` sync/status banner + shared labels + telemetry summary migrated to ARB keys/placeholders
  - progress: `Sync Diagnostics` major labels/actions migrated to ARB keys (mixed state; row-status text cleanup still pending)
  - progress: `ui_kit` ErrorRetry defaults + ConfirmDialog default confirm label moved to ARB
  - status: current shared/common widget slice complete
- `I18N-2` Core operations migration
  - dashboard, sales, customers, products, expenses
  - progress: Dashboard slice started (alerts bell states, low-stock card labels, quick actions moved to ARB)
  - progress: Sales list + sale detail screens migrated to ARB (create/sales shell/credit payment still bridge)
  - progress: Customers list + customer form + customer detail migrated to ARB (Customers batch complete)
  - progress: Products list + form + detail migrated to ARB (`stock_adjustment_screen` still bridge)
  - progress: Credit payment + stock adjustment + expenses screens migrated to ARB
  - progress: `CreateSaleScreen` + `SalesScreen` migrated to ARB (dialogs/risk warnings/empty states/cart placeholders)
  - status: complete (Dashboard, Sales, Customers, Products, Expenses core screens migrated to ARB/AppLocalizations)
- `I18N-3` Reports + Intelligence + Billing migration
  - reports screens, alerts, business health, product insights, billing screens, PDF labels
- `I18N-4` Settings/Auth/Onboarding/Admin migration
  - settings, auth, onboarding, profile, sync diagnostics
  - progress: `SettingsScreen` + `ProfileScreen` migrated to ARB (section headers/tiles/store-role labels/sign-out dialog)
  - progress: `LandingPage` + `ForgotPasswordPage` + `AuthScreen` migrated to ARB (auth batch complete)
  - progress: `OnboardingScreen` + `BusinessSettingsScreen` + `TaxSettingsScreen` + `SubscriptionScreen` + `UserManagementScreen` migrated to ARB
  - status: complete (no `context.tr(...)` in auth/onboarding/profile/settings presentation scope)
- `I18N-5` Cleanup + guardrails
  - reduce/remove `context.tr(...)` in migrated files
  - add checks for missing ARB keys / new inline bilingual strings
  - progress: `display_labels.dart` moved to `AppLocalizations` (no bridge helper usage in `mobile/lib`)
  - progress: added guard script `/Users/laxmankc/Startup/SME/sme-digital/mobile/tool/check_i18n_bridge_usage.sh`
  - progress: wired i18n guard + `gen-l10n` + `analyze` into `/Users/laxmankc/Startup/SME/sme-digital/.github/workflows/mobile-ci.yml`
  - status: complete (baseline guardrails; CI wiring can call the script)

## Known Remaining Risks / Gaps

- Manual QA still required for unstable-network scenarios (`offline -> reconnect`, duplicate protection, delete propagation)
- Billing PDF runtime behavior needs device-level verification (print/share/Nepali font rendering)
- CI mobile workflow should stay green for `flutter gen-l10n`, i18n bridge guard, analyze, and tests (watch for environment-specific native asset fetch issues)
- Some advanced conflict-resolution UX remains basic (diagnostics exists, but row-level guided resolution can improve)

## Validation (Latest Snapshot)

Backend:
- Sync/auth/store/intelligence targeted tests passing (latest targeted runs previously verified)
- Import smoke check passing (`import app.main`)

Mobile (i18n completion snapshot):
- `flutter gen-l10n` passing
- `flutter analyze` passing (`No issues found!`)
- i18n bridge guard passing: `bash /Users/laxmankc/Startup/SME/sme-digital/mobile/tool/check_i18n_bridge_usage.sh` -> `OK: no context.tr(...) usage found.`
- targeted intelligence UI/provider tests require native `sqlite3` asset build and were blocked by transient network download failure (GitHub release fetch in test hook)

Mobile:
- `flutter analyze` passing on recently touched files (localization + settings + dashboard + billing/expense batches)
- Billing unit/integration tests passing (baseline)
- Intelligence UI/provider tests passing (baseline)

Manual QA:
- `⚪ Pending` consolidated run against current branch after latest localization/settings updates

## Manual QA Checklist (Pending)

- [ ] Offline create product/customer/expense/sale -> reconnect -> backend reflects all
- [ ] Delete sync propagation (product/customer/expense) behaves correctly
- [ ] Token expiry during sync refreshes/resumes cleanly
- [ ] Unstable network toggling does not create duplicate rows
- [ ] Low stock threshold consistency across mobile/backend sync
- [ ] Billing PDF generation/share/print on device (English + Nepali)
- [ ] Account switch/store isolation (no data collision)

## Docs Index (Authoritative References)

Core / Offline:
- `/Users/laxmankc/Startup/SME/sme-digital/docs/offline-sync-contract.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/offline-conflict-policy.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/offline-rollout-checklist.md`

Intelligence / Risk:
- `/Users/laxmankc/Startup/SME/sme-digital/docs/intelligence-risk-layer.md`

Billing / PDF / i18n:
- `/Users/laxmankc/Startup/SME/sme-digital/docs/billing_pdf_i18n_mobile.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/billing_mobile_rollout_checklist.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/i18n-migration-plan.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/i18n-migration-tracker.md`

Production / Testing / Docs index:
- `/Users/laxmankc/Startup/SME/sme-digital/docs/backend-production-readiness.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/test-strategy.md`
- `/Users/laxmankc/Startup/SME/sme-digital/docs/README.md`

## Maintenance Rules (for this file)

- Keep only current status and next actions here
- Do not append per-slice implementation logs
- Replace validation results with latest snapshot (do not stack old runs)
- Link to docs/specs instead of duplicating long text
