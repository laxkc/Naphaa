# SME Digital Progress

Last updated: 2026-03-04

## Current Active Plan

Status: `Completed`
Focus: `Progressive onboarding refactor for mobile app`

Goal:
- remove blocking pre-dashboard onboarding
- move to `Language -> OTP -> Dashboard`
- push business configuration into progressive in-app setup

## Product Rules

- [x] User reaches dashboard through the shortest path: `Language -> OTP -> Dashboard`
- [x] Language is the only pre-auth setup step
- [x] Auth becomes phone OTP based, not password based
- [x] Signup and login are unified into one flow
- [x] No onboarding wizard blocks dashboard access
- [x] Backend auto-creates user/store/default settings after OTP verification
- [x] Dashboard becomes the first-use setup surface
- [x] Business/tax/calendar/unit settings stay editable later in settings

## Current-State Findings

- [x] `LandingPage` is still the unauthenticated home screen
- [x] `AuthScreen` still uses separate password login and signup flows
- [x] `OnboardingScreen` still exists as a post-auth gate
- [x] onboarding selections are mostly UI-only and not persisted as canonical business setup
- [x] `ForgotPasswordPage` is still a placeholder local-only screen
- [x] startup still seeds sample business data when the local DB is empty
- [x] mobile API base URL behavior still needs environment-driven cleanup

## Phase ONB0 — Freeze New Startup Architecture

- [x] Publish target startup rule set:
- [x] `language selected? -> auth token? -> dashboard/auth`
- [x] remove wizard-based setup from critical path
- [x] define backend-owned default store values:
- [x] currency = `NPR`
- [x] calendar = `BS`
- [x] timezone = `Asia/Kathmandu`
- [x] tax disabled by default via local business/tax preferences until backend tax profile exists
- [x] document progressive setup points inside app (`Business Settings`, `Tax Settings`, `Billing Settings`)
- [x] Acceptance: startup architecture is frozen before implementation

## Phase ONB1 — Language Gate

- [x] Add a dedicated `LanguageSelectionScreen`
- [x] Show it only when no language has been selected yet
- [x] Persist choice locally using existing locale preferences
- [x] Route immediately to auth gate after selection
- [x] Keep language switch available later in settings
- [x] Acceptance: first-run users choose language before any auth or dashboard content

## Phase ONB2 — Backend OTP Authentication

- [x] Add OTP request endpoint
- [x] Add OTP verify endpoint
- [x] Auto-create user on successful verify if phone is new
- [x] Auto-create store on successful verify if phone is new
- [x] Issue access token + refresh token from OTP verify
- [x] Rate limit OTP request and verify attempts
- [x] Add OTP expiry and resend policy
- [x] Keep `/auth/me` returning user + store snapshot after OTP auth
- [x] Acceptance: backend supports passwordless auth without requiring separate signup

## Phase ONB3 — Mobile OTP Flow

- [x] Replace password auth UI with one `OtpAuthScreen`
- [x] Step 1: phone input
- [x] Step 2: OTP input
- [x] Add resend OTP behavior
- [x] Remove separate signup/login toggle from primary flow
- [x] Wire success path into existing auth/session state
- [x] Acceptance: new and existing users authenticate through one phone-based flow

## Phase ONB4 — Dashboard-First Entry

- [x] Remove `OnboardingScreen` from post-auth routing
- [x] Route auth success directly to `AppShell`
- [x] Remove onboarding-complete flag from startup gating logic
- [x] Remove remaining onboarding assets instead of keeping them in active fallback paths
- [x] Acceptance: authenticated user always lands in dashboard immediately

## Phase ONB5 — Progressive Setup Inside App

- [x] Move setup ownership to in-app surfaces:
- [x] `Business Settings`
- [x] `Tax Settings`
- [x] `Billing Settings`
- [x] add non-blocking dashboard setup prompts:
- [x] complete business profile
- [x] enable tax
- [x] add first product
- [x] set invoice prefix
- [x] make prompts dismissible and context-aware
- [x] Acceptance: no setup is forced, but missing critical configuration is clearly surfaced

## Phase ONB6 — First-Run Empty Dashboard

- [x] Remove production dependency on `seedIfEmpty()` for first-run UX
- [x] Keep sample/demo seeding only behind explicit debug/dev path if still needed
- [x] Ensure first dashboard can legitimately show:
- [x] today sales = `0`
- [x] products = `0`
- [x] customers = `0`
- [x] quick actions for `Add Product`, `Record Sale`, `Add Customer`, `Setup Business`
- [x] Acceptance: first-run dashboard reflects a real empty business, not seeded demo data

## Phase ONB7 — Backend Defaulting and Store Bootstrap

- [x] Ensure backend-created store defaults are canonical:
- [x] `currency = NPR`
- [x] `calendar_mode = BS`
- [x] `business_timezone = Asia/Kathmandu`
- [x] `locale_default = selected language` when available
- [x] persist those defaults so mobile reads them via `/auth/me` and `/stores/me`
- [x] Acceptance: mobile does not invent canonical first-business defaults on its own

## Phase ONB8 — Cleanup of Legacy Auth and Onboarding

- [x] Decommission `LandingPage` as startup root
- [x] Decommission password-based `AuthScreen` from primary user flow
- [x] Decommission `ForgotPasswordPage` unless a real backend recovery flow exists
- [x] Decommission `OnboardingScreen` after migration is complete
- [x] Remove unused onboarding-complete preference gating logic
- [x] Acceptance: there is one clear first-run/auth path in the codebase

## Phase ONB9 — Migration and Rollout

- [x] Decide migration behavior for existing password users
- [x] Keep legacy auth fallback only at backend/service level while OTP rollout is primary
- [x] Document that a dedicated feature flag is not required because legacy endpoints remain available for rollback
- [x] Validate account creation, token refresh, logout, and returning-user startup
- [x] Acceptance: progressive onboarding can replace the old flow without breaking existing accounts

## Phase ONB10 — Testing and UX Validation

- [x] First install: language -> OTP -> dashboard
- [x] Returning user with valid token -> dashboard directly
- [x] Returning user with expired token -> OTP flow
- [x] New user auto-creation path
- [x] Existing user OTP login path
- [x] Dashboard first-run empty state regression tests
- [x] No sample seed data in production first-run flow
- [x] Business defaults visible in profile/settings after first login
- [x] Acceptance: startup and onboarding behavior is production-safe and measurable

## Delivery Order

- [x] Step 1: `ONB0 -> ONB2`
- [x] Step 2: `ONB1 -> ONB3`
- [x] Step 3: `ONB4 -> ONB6`
- [x] Step 4: `ONB7 -> ONB8`
- [x] Step 5: `ONB9 -> ONB10`

## Final Artifacts

- [x] Rollout and migration doc: `/Users/laxmankc/Startup/SME/sme-digital/docs/progressive-onboarding-rollout.md`
- [x] Startup flow widget tests: `/Users/laxmankc/Startup/SME/sme-digital/mobile/test/integration/onboarding_startup_flow_test.dart`
- [x] Backend OTP/default bootstrap tests: `/Users/laxmankc/Startup/SME/sme-digital/backend/tests/api/test_auth_and_store.py`
