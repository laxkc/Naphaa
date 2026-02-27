# Mobile Design Refactor Plan

Last updated: 2026-02-27
Source: `/Users/laxmankc/Startup/SME/sme-digital/web/DESIGN.md`

## 1. Objective

Align the full mobile app UI to the web design system with strict governance:

- no inline token styling
- no random hex values
- max two brand accents
- single font family
- restrained gradient usage
- accessibility-first defaults

## 2. Phase Plan (Execution)

1. D0 Audit and gap mapping
2. D1 Theme foundation and reusable primitives
3. D2 App shell and navigation consistency
4. D3 Auth/Onboarding/Profile
5. D4 Dashboard and quick actions
6. D5 Sales
7. D6 Products/Inventory
8. D7 Customers/Credit
9. D8 Expenses
10. D9 Reports/Intelligence
11. D10 Billing/Invoice UI
12. D11 Settings
13. D12 Sync/Diagnostics UX
14. Cross-cutting hardening (i18n/accessibility/responsive/regression)

## 3. D0 Audit Snapshot (Started)

### 3.1 Screen inventory

Feature screens detected under `mobile/lib/features/*/presentation`: 38

Modules:
- auth
- billing
- customers
- dashboard
- expenses
- onboarding
- products
- profile
- reports
- sales
- settings
- sync

### 3.2 Design debt signal scan

Heuristic scan (`Color(0x...)`, direct `TextStyle(...)`) by module:

- auth: files=3, hex_refs=9, textstyle_refs=17
- billing: files=3, hex_refs=0, textstyle_refs=20
- customers: files=3, hex_refs=0, textstyle_refs=9
- dashboard: files=1, hex_refs=2, textstyle_refs=18
- expenses: files=1, hex_refs=5, textstyle_refs=4
- onboarding: files=1, hex_refs=0, textstyle_refs=4
- products: files=4, hex_refs=0, textstyle_refs=11
- profile: files=1, hex_refs=0, textstyle_refs=1
- reports: files=10, hex_refs=2, textstyle_refs=17
- sales: files=5, hex_refs=0, textstyle_refs=22
- settings: files=5, hex_refs=0, textstyle_refs=9
- sync: files=1, hex_refs=0, textstyle_refs=10
- core: files=24, hex_refs=18, textstyle_refs=23
- shared: files=2, hex_refs=10, textstyle_refs=9

Notes:
- `hex_refs` indicates likely token violations; highest immediate hotspots are `auth`, `expenses`, `dashboard`, `core`, and `shared`.
- `textstyle_refs` indicates custom style drift risk and should be normalized through shared typography tokens.

### 3.3 Priority backlog from audit

P0 (start first):
- `mobile/lib/core/theme/app_theme.dart` token map still old teal palette and spacing/radius scale mismatches DESIGN.md
- `mobile/lib/features/auth/presentation/auth_screen.dart` has local palette constants and direct hex usage
- `mobile/lib/features/dashboard/presentation/dashboard_screen.dart` includes gradient and ad-hoc colors in high-traffic screen
- `mobile/lib/features/expenses/presentation/expenses_screen.dart` uses per-category random colors and inconsistent chip palette
- `mobile/lib/shared/widgets/ui_kit.dart` includes random avatar/status/skeleton colors not tied to token system

P1:
- reports and sync presentation visual consistency
- sales/billing heavy `TextStyle(...)` consolidation to typography tokens

P2:
- remaining stylistic cleanup in settings/products/customers/profile/onboarding

## 4. D1 Work Package (Next)

1. Replace color tokens in `app_theme.dart` with DESIGN.md navy/coral system.
2. Align spacing/radius tokens to 8pt/6-8-12-16-pill scales.
3. Introduce/standardize reusable primitives in shared widgets:
   - app button variants
   - status chip/badge
   - card container
   - section header
4. Remove local color constants from auth/dashboard/expenses and rebind to theme tokens.
5. Add quick guard check script for random hex in feature modules.

## 5. Acceptance for D0 Completion

- screen inventory documented
- initial design debt map documented
- P0/P1/P2 backlog identified
- D1 target files and first cut scope defined
