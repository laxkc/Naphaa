# Local DB Encryption Assessment (Flutter Mobile)

## Goal

Protect sensitive offline data at rest while preserving offline-first reliability.

## Current State

- Mobile uses `sqflite` with a plain SQLite database.
- Sensitive data stored locally can include:
  - customers (phone, balances)
  - sales and payments
  - expenses
  - sync outbox payloads / errors

## Options Evaluated

### Option A: SQLCipher-backed SQLite (`sqflite_sqlcipher` or equivalent)

Pros
- Keeps relational SQLite model and existing queries
- Strong at-rest encryption for DB file
- Best fit for current architecture (many tables + joins + migrations)

Cons
- Plugin/platform setup complexity (iOS/Android native dependencies)
- Migration of existing plaintext DB required
- Slight performance overhead on low-end devices

### Option B: Application-layer encryption of selected fields

Pros
- No DB engine/plugin change
- Incremental rollout possible

Cons
- Hard to do correctly and consistently
- Querying/filtering becomes difficult
- Leaves schema and many values exposed

### Option C: Keep plaintext DB and rely on OS disk encryption only

Pros
- Zero engineering effort

Cons
- Weakest protection for rooted/jailbroken/device-compromise scenarios
- Does not meet desired at-rest protection standard

## Recommendation

- Use **SQLCipher-backed SQLite** for production mobile builds.
- Keep current `sqflite` path in dev/test initially if needed, but converge to one encrypted path for release.

## Key Management Plan

- Generate a random per-install DB key on first run.
- Store the DB key in OS secure storage:
  - iOS Keychain
  - Android Keystore (via secure storage plugin)
- Never derive the DB key from the user password.
- Do not log the DB key or include in backups/exports.

## Migration Strategy (Existing Installations)

1. Detect plaintext DB (legacy installs).
2. Open legacy DB read-only (or controlled mode).
3. Create encrypted DB file.
4. Copy schema + data table-by-table in a transaction.
5. Verify row counts and critical checksums.
6. Swap files atomically.
7. Keep one-time rollback backup until first successful app restart.

## Rollout Plan

1. Spike branch on simulator/device (performance + plugin stability)
2. Migration test on seeded legacy DBs
3. Beta rollout to internal users
4. Add telemetry for migration success/failure
5. Enable for production

## Risks / Open Questions

- Cross-platform plugin stability and maintenance
- Migration performance on large offline datasets
- Backup/restore behavior for encrypted DBs
- Secure handling of DB key across app reinstall/device restore scenarios

## Acceptance Criteria

- DB file is encrypted at rest
- App continues to work offline
- Existing plaintext installs migrate without data loss
- Sync/outbox behavior remains unchanged after migration

