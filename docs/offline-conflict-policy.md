# Offline Conflict Policy (Phase 5)

Last updated: 2026-02-23

## Current Policy (v1)

This app is optimized for Nepal SME usage with unstable internet and a simple operating model.

### Operational assumption

- `Single primary device per store` (recommended)

This minimizes stock and credit conflicts in early-stage rollout.

## Merge Rules (Current Implementation)

### 1. Idempotent operation replay

- Duplicate push events are ignored using `device_id + op_id` idempotency semantics
- Legacy clients fall back to fingerprint dedupe

### 2. Sales replay safety

- Backend `/sync/push` sale projector ignores duplicate sale `UPSERT` if sale ID already exists
- This prevents double stock deduction and double customer balance increments

### 3. Local-first + server projection

- Mobile writes locally first
- Backend projects accepted events into canonical tables
- Mobile later pulls server events and reconciles local cache

### 4. Tombstones / Deletes

- Deletes are synchronized as explicit `DELETE` events (not hard deletes on mobile cache)
- Current support:
  - product delete
  - customer delete
  - expense delete (backend + sync protocol path)

## Planned (Future Multi-Device)

These are not required for v1:

- field-level conflict resolution
- vector clocks / per-record versioning
- server-authoritative merge with conflict feedback per event
- user-visible conflict queue

## Guidance for Team

- Keep inventory mutations event-based (`sale`, `refund`, `adjust_stock`)
- Avoid direct total overwrites for stock in multi-device scenarios
- Prefer soft-delete + tombstone sync over hard-delete

