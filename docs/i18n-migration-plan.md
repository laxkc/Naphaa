# i18n Migration Plan (Full Application)

Last updated: 2026-02-25

## Goal

Migrate the mobile app from the current inline bilingual helper pattern:

- `context.tr('English', 'नेपाली')`

to a production-scale, industry-standard localization system:

- Flutter `AppLocalizations`
- ARB translation files (`app_en.arb`, `app_ne.arb`)
- key-based translations (`l10n.someKey`)

This improves maintainability, consistency, translation quality, and future language support.

## Current State (Why Migration Is Needed)

Current approach works well as a migration bridge and for rapid patching, but it is not scalable long-term because:

- translations are embedded directly in UI code
- same text can drift across screens
- adding a 3rd language requires code changes everywhere
- translators cannot work on a centralized translation source
- missing translation coverage is hard to audit

## Target Architecture (Production)

### Localization source

- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/l10n/app_en.arb`
- `/Users/laxmankc/Startup/SME/sme-digital/mobile/lib/l10n/app_ne.arb`

### Access pattern in UI

Use generated `AppLocalizations`:

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.dashboardQuickActionsTitle);
```

### Migration bridge policy

- `context.tr(...)` remains allowed temporarily during migration
- `context.tr(...)` is considered transitional only
- migrated screens should use `AppLocalizations` keys only

## Scope (Full Application)

Migrate all user-visible mobile strings in:

- Auth
- Onboarding
- Dashboard
- Products
- Sales
- Customers
- Expenses
- Reports (including Intelligence/Risk)
- Billing / Invoice screens
- Settings / Profile
- Sync Diagnostics / sync banners
- Dialogs, banners, empty states, tooltips, chips, quick actions
- Billing PDF labels (via shared translation keys or mirrored key mapping)

Out of scope (do not localize as UI strings):

- DB column names
- API payload keys
- sync/entity operation codes
- internal enum raw values used in storage/API (`CASH`, `UPSERT`, etc.)
- debug logs and internal error normalization text (unless user-visible)

## Key Naming Convention

Use hierarchical keys:

- `feature.section.element`

Examples:

- `dashboard.quickActionsTitle`
- `dashboard.lowStockItemsTitle`
- `sales.quickAddProductTitle`
- `sales.creditRiskWarningTitle`
- `customers.riskExplanationTitle`
- `syncDiagnostics.clearFailedRowsConfirmTitle`
- `billing.invoiceDetail.recordPayment`

### Rules

- prefer descriptive names over raw-English key names
- keep wording stable (keys should not change frequently)
- do not encode UI position in keys unless necessary
- avoid duplicate semantic keys for same meaning (reuse common keys when identical)

## Dynamic Strings (Placeholders, Plurals, Select)

Dynamic UI strings must move to ARB placeholders/plurals instead of inline interpolation.

Examples:

- `{count} alerts`
- `No match for "{query}"`
- `{qty} left`
- `{days} days`
- item/item(s) plural labels

Why:

- proper grammar across languages
- maintainable translation logic
- avoids broken pluralization in Nepali/English

## Enum / Status Display Localization

Keep raw values in DB/API and localize only in presentation layer.

Examples to localize via helpers:

- payment methods (`CASH`, `QR`, `BANK`, `CREDIT`)
- invoice statuses (`draft`, `issued`, `paid`, `overdue`, `cancelled`)
- alert severity (`critical`, `warn`, `info`)
- risk levels (`High`, `Medium`, `Low`)
- expense categories (display labels only)

Recommended pattern:

- `String paymentMethodLabel(BuildContext context, String method)`
- `String invoiceStatusLabel(BuildContext context, InvoiceStatus status)`

## Billing PDF Localization Strategy

Billing PDF labels should align with the same translation keys used in UI where possible.

Requirements:

- select language from invoice snapshot (`invoice.language` or business-language snapshot)
- preserve immutable invoice display behavior (snapshot-based, not current settings)
- support Nepali font rendering with graceful fallback

Recommended approach:

- use `AppLocalizations`-style key map (or a small shared translation adapter for PDF generation)
- avoid hardcoding parallel PDF-only labels in the PDF service

## Migration Phases (Full App)

### I18N-0: Conventions + Tracker

- define key naming convention
- define rules for user-visible vs internal strings
- mark `context.tr(...)` as migration-only
- create migration tracker (screen status matrix)

### I18N-1: Shared/Common UI

Migrate common reusable strings first:

- dialogs
- banners
- empty states
- common actions (`Save`, `Cancel`, `Retry`, `Delete`, `Loading`, `Error`)
- shared widgets in `ui_kit.dart` where applicable

### I18N-2: Core Operations

Migrate high-traffic screens:

- Dashboard
- Sales
- Customers
- Products
- Expenses

### I18N-3: Reports + Intelligence + Billing

- reports screens
- alerts / business health / product insights / credit aging
- invoice screens
- PDF labels

### I18N-4: Settings / Auth / Onboarding / Admin

- settings
- profile
- auth / forgot password
- onboarding
- sync diagnostics
- support/admin screens

### I18N-5: Cleanup + Guardrails

- reduce/remove `context.tr(...)` usage in migrated files
- add checks for missing ARB keys
- add guardrails to prevent new inline bilingual strings in migrated files

## Implementation Rules (Practical)

- Migrate screen-by-screen, not big-bang
- Keep behavior unchanged while replacing text sources
- For dynamic strings, prefer ARB placeholders over string concatenation
- Preserve raw enum values for API/storage; localize display only
- Update tests/snapshots if text assertions change

## Translation Ownership Workflow (Production)

Define clear ownership so translations stay consistent as the team grows.

Recommended roles:

- **Developers**: add keys, wire UI to `AppLocalizations`, provide English source text/context
- **Product/Founder**: approve final wording and consistency for business terms
- **Translator / Language reviewer (Nepali)**: maintain Nepali wording quality and terminology consistency
- **QA**: verify rendering, overflow, placeholders, and flows in supported languages

Recommended PR workflow:

1. Developer adds/updates ARB keys and UI usage
2. Translation review for Nepali wording (especially business/finance terms)
3. QA checks key screens and dialogs in both languages
4. Merge only after ARB generation + localization checks pass

## Key Lifecycle Rules (Maintainability)

Without lifecycle rules, ARB files become noisy and hard to maintain.

Rules:

- Do not rename keys casually (treat keys as stable IDs)
- Prefer updating translation values over renaming keys unless semantics changed
- If semantics changed significantly, create a new key and mark the old key for cleanup
- Track deprecated keys and remove them in periodic cleanup (not ad hoc)
- Avoid duplicate semantic keys with slightly different names

Recommended cleanup cadence:

- i18n key cleanup every 1-2 release cycles

## CI / Guardrails (Explicit)

Make the migration enforceable with CI, not only convention.

Required checks (recommended):

- ARB/generation check passes (`gen_l10n`)
- No missing required translations for `en` and `ne`
- No syntax/placeholder mismatches across locales
- `flutter analyze` passes after localization generation

Migration guardrail (important):

- Fail or warn if new `context.tr(...)` is introduced in files already marked as migrated

Optional quality checks:

- Warn on duplicate English values across many keys (manual review signal)
- Warn on very long untranslated strings likely to overflow on mobile

## Localization Style Guide (Content Consistency)

Define wording rules so translations are consistent across the app.

Recommended standards:

- **Tone**: consistent tone (formal or semi-formal Nepali) across all screens
- **Terminology**: standardize core business terms:
  - Invoice
  - Credit
  - Stock
  - Outstanding
  - Payment
  - Report
  - Sync
  - VAT/PAN
- **Transliteration policy**:
  - decide when to transliterate (e.g. `PDF`, `VAT`, `QR`)
  - decide when to fully translate (e.g. `Save`, `Delete`, `Retry`)
- **Punctuation/spacing**:
  - consistent use of colon, quotes, and spacing around values
- **Numerals**:
  - define default (English digits now)
  - future option for Nepali digits should be explicit and configurable

This should be documented once and followed across UI + PDF labels.

## PDF Font & Offline Rendering Policy (Billing)

Billing PDFs are legal/operational artifacts, so font behavior must be deterministic.

Production recommendation:

- **Bundle Nepali-capable fonts with the app** for invoice generation
- Do not rely only on runtime font fetch for invoice PDFs

Why:

- invoice generation must work offline
- remote font fetch can fail on unstable internet
- runtime fallback can change layout/wrapping unexpectedly

Suggested policy:

- Primary: bundled Nepali font (e.g. Noto Sans Devanagari)
- Fallback: bundled Latin font
- Runtime remote font fetch (if kept) should be optional enhancement, not dependency

QA requirements:

- verify Nepali glyph rendering
- verify wrapping in long item names and terms/footer text
- verify mixed-language invoice content (Nepali labels + English product names)

## Invoice Snapshot Localization Policy (Immutability)

Issued invoices are immutable; localization changes must not silently alter invoice meaning.

Rules:

- Store invoice display snapshots at issue time (already part of billing design):
  - language
  - currency
  - tax mode/rate
  - business identity fields (name/address/PAN/VAT)
- Re-rendering an existing issued invoice should use snapshot values, not current business settings
- Translation improvements may change labels, but not numeric meaning or tax computations

Recommended practice:

- For legally sensitive deployments, consider snapshotting rendered invoice labels too (future enhancement)
- For v1, snapshot config + stable translation keys is acceptable if tested carefully

## QA Plan

### Automated (Recommended)

- missing ARB key checks
- generated localization compile checks
- widget smoke tests for key screens in `en` and `ne`
- placeholder/plural formatting tests

### Manual

Verify on small and large screens:

- text overflow / truncation
- dialog/title wrapping
- chip labels and button text fit
- dashboards and reports render correctly in both languages
- billing PDF labels and wrapping in English/Nepali

## Deliverables

1. ARB key conventions in use (`app_en.arb`, `app_ne.arb`)
2. Migration tracker by screen/feature
3. First migrated high-traffic batch (recommended: Dashboard + Sales + Customers)
4. Guardrails for new strings in migrated areas

## Recommended First Implementation Batch

Start with:

1. Dashboard
2. Sales
3. Customers

Reason:

- highest daily usage
- broad coverage of dialogs, lists, badges, alerts, dynamic counts
- immediate visible quality improvement

## Success Criteria

- migrated screens use `AppLocalizations` keys (not inline bilingual strings)
- dynamic strings use placeholders/plurals
- translations are centralized in ARB files
- adding a new language requires translation updates, not UI code edits
