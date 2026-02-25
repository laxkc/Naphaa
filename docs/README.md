# Docs Index (Current)

Last updated: 2026-02-24

This folder contains a mix of:

- current implementation docs/policies (authoritative for the current codebase)
- product/design specs (target behavior and future work)
- generated/reference snapshots (for compatibility and audits)

## Recommended Reading Order (Current System)

1. `architecture.md`
   - high-level app architecture (mobile + backend)
2. `offline-sync-contract.md`
   - sync payload/authority contract for offline-first behavior
3. `offline-conflict-policy.md`
   - v1 conflict and merge rules
4. `offline-rollout-checklist.md`
   - manual rollout and verification checklist
5. `backend-production-readiness.md`
   - backend readiness status and remaining production hardening
6. `test-strategy.md`
   - testing layers, coverage focus, and release gates
7. `intelligence-risk-layer.md`
   - Intelligence + Risk Layer product/technical spec (v1)

## Intelligence + Risk Docs

- `intelligence-risk-layer.md`
  - full product + technical spec for the Intelligence + Risk layer
- `mobile-cache-delete-policy.md`
  - local cache deletion/tombstone behavior for offline-first mobile sync

## Security / Access / Platform Docs

- `rbac-foundation.md`
  - backend RBAC foundation scope and next steps (not full enforcement)
- `local-db-encryption-assessment.md`
  - mobile local DB encryption plan and migration assessment
- `localization-strategy.md`
  - i18n/l10n strategy and implementation guidance
- `i18n-migration-plan.md`
  - full-application ARB migration plan (production-scale i18n refactor)
- `i18n-migration-tracker.md`
  - execution tracker for screen-by-screen ARB migration progress

## API / Contract Reference Docs

- `api-spec.md`
  - human-readable API specification (v1)
- `api-contract.md`
  - API contract policy and compatibility guidance
- `openapi.v1.json`
  - OpenAPI snapshot (reference/export)
- `spi-spec.md`
  - external integration summary / quick map

## Product / UX / Data Reference Docs

- `product-requirements.md`
  - MVP product requirements
- `mobile-design.md`
  - mobile UI/UX design guidance
- `database-schema.md`
  - schema reference overview
- `data-seeding.md`
  - backend fake data seeding usage

## Note on Deletions

No docs were deleted in this pass because the remaining files are either:

- active implementation docs,
- useful future/RFC documents, or
- reference snapshots/specs used for audits and API comparisons.

If you want a stricter cleanup next, we can do an `archive/` pass (move older MVP/spec docs that no longer reflect the current implementation).
