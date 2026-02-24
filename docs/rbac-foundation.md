# RBAC Foundation (Backend)

## Scope of This Foundation

This is the **foundation layer**, not full role enforcement across all endpoints.

Implemented foundation pieces:
- `users.role` column (default: `owner`)
- role included in `/api/v1/auth/me` profile response
- role claim included in newly issued access/refresh tokens
- reusable backend dependency helper: `require_roles(...)`

## Current Model (MVP)

- `owner`: full store access (current default behavior)
- `staff`: operational access (sales, customers, products; no settings/exports/refunds by policy)
- `viewer`: read-only reporting/inventory visibility (future)

## Current Limitation

- The app currently maps a single store to `owner_user_id`.
- There is no `store_users` membership table yet.
- So roles are currently **user-level defaults**, not per-store memberships.

## Next Implementation Slice (to complete full RBAC)

1. Add `store_users` (membership) table
   - `store_id`, `user_id`, `role`, `is_active`, timestamps
2. Resolve current store membership in `get_current_store`
3. Enforce `require_roles(...)` on sensitive endpoints
   - refunds
   - exports
   - settings/business config
   - user management
4. Add user/store role management endpoints
5. Add authorization matrix tests by role

## Suggested First Enforcement Targets

- `sales/{id}/refund` -> `owner` only
- `exports/*` -> `owner` only
- tax/business settings -> `owner` only
- product stock adjustment -> `owner` or `staff`

## Why This Foundation Matters

- Avoids a future breaking API shape change for auth/profile
- Provides a reusable permission hook (`require_roles`)
- Makes it straightforward to introduce memberships and endpoint gating incrementally

