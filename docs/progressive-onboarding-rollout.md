# Progressive Onboarding Rollout

Last updated: 2026-03-04

## Goal

Replace the old `landing -> password auth -> onboarding wizard` flow with:

1. Language
2. Phone OTP
3. Dashboard

This rollout keeps existing accounts usable while making the new progressive flow the only mobile-first path.

## Current Contract

### Mobile-first startup

- First install with no saved locale -> `LanguageSelectionScreen`
- Saved locale and no valid session -> OTP `AuthScreen`
- Valid session -> `AppShell`
- Expired/invalid session at startup -> return to OTP `AuthScreen`

### Canonical first-business defaults

Backend owns these defaults during OTP verify:

- `currency = NPR`
- `calendar_mode = BS`
- `business_timezone = Asia/Kathmandu`
- `locale_default = selected language` when provided

Tax default is currently a local application default:

- `tax_enabled = false`

That is not yet part of the canonical backend store model. Mobile and billing preferences must continue to default tax to disabled until store-level tax settings are modeled server-side.

## Existing User Migration

### Existing password users

- Password users are not deleted or migrated destructively.
- Backend still supports:
  - `POST /api/v1/auth/login`
  - `POST /api/v1/auth/register`
  - refresh/logout flows
- Mobile no longer exposes password auth as the primary UI.
- Existing users sign in through OTP using the same phone number.

### Existing tokens

- Existing access/refresh token flow remains valid.
- Returning users with a valid session go directly to dashboard.
- Returning users with expired/revoked tokens are redirected to OTP auth at startup.

### Existing local data

- Local store/account scope is still keyed by authenticated store identity.
- If authenticated phone/store changes, mobile clears local scoped data and sync cursors before continuing.

## Rollout Decision

No dedicated backend feature flag is being added right now.

Reason:

- legacy password endpoints remain available as backend fallback
- mobile already moved to OTP-only UI
- rollback can be done without schema reversal

This is acceptable at the current stage because fallback risk is covered at the API layer instead of by running two parallel mobile auth entry points.

## Rollback Plan

If OTP delivery or provider reliability becomes unacceptable:

1. Keep current backend OTP endpoints deployed.
2. Re-enable password auth entry in mobile behind a small UI patch.
3. Keep refresh/logout/session behavior unchanged.
4. Do not change store/user data shape.

Rollback is UI-level, not schema-level.

## Acceptance Criteria

### Account creation

- New phone can request OTP
- New phone can verify OTP
- User is auto-created
- Store is auto-created with canonical defaults

### Existing account access

- Existing phone can request OTP
- Existing phone can verify OTP
- Existing account identity is preserved

### Session lifecycle

- Valid token -> dashboard direct
- Expired/revoked token -> OTP auth
- Refresh rotation still works
- Logout clears local auth state and revokes refresh token

### First-run UX

- No pre-dashboard onboarding wizard
- No production demo data injection
- Empty dashboard is truthful:
  - sales `0`
  - products `0`
  - customers `0`
- Quick actions remain available
- Business/tax/billing setup is non-blocking

## Operational Notes

- OTP debug codes must only be returned when backend `DEBUG=true`
- Production SMS delivery still needs provider wiring and monitoring
- Backend rate limiting and OTP expiry are already required parts of the flow

## Remaining Follow-up Outside This Rollout

- Add canonical backend tax settings to store/business profile
- Add production SMS provider integration and observability
- Optionally remove legacy password endpoints after OTP adoption is stable
