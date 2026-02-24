# Mobile Cache Delete Policy

This app is offline-first, but the backend remains the system source of truth.

## Policy

- `customer` sync `DELETE`: keep a local tombstone (`is_deleted = 1`)
  - Reason: customer history/credit ledgers may still reference the customer.
- `product` sync `DELETE`: hard-delete from mobile cache (cache prune)
  - Reason: backend preserves soft-delete history; mobile product UI/list queries stay simpler and faster.
- `expense` sync `DELETE`: hard-delete from mobile cache (cache prune)
  - Reason: backend preserves soft-delete/audit history; mobile cache only needs active expenses for runtime UX.

## Important

- Backend uses soft delete for `products`, `customers`, and `expenses`.
- Mobile hard delete for `product`/`expense` is a cache policy, not loss of system history.
- If a future mobile audit/ledger UI requires local historical deleted rows, add local tombstones for those tables and filter in repositories.

