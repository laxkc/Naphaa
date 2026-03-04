# ADR: Sales + Inventory + Sync Invariants

## Status
Accepted

## Date
2026-03-04

## Context
The mobile app is offline-first and must keep sales, stock, and sync behavior consistent under weak internet.
Historically, multiple sales UI flows and mixed assumptions created drift risk.

## Decision
1. Canonical sales UI flow:
   - `SalesListScreen` for history/listing.
   - `CreateSaleScreen` for checkout/create.
   - Legacy duplicate screen paths are removed.

2. Sale invariants:
   - Every sale has one or more items.
   - Sale total is derived from items/payments, not manual total entry.
   - Credit requires customer context.
   - Corrections happen via explicit events (`void`, `refund`), not hard delete.

3. Inventory invariants:
   - Inventory state is event-derived via `stock_movements`.
   - `products.stock_qty` is a projection/cache, not primary truth.
   - Sale, refund, stock adjustment, and invoice issue emit movement rows.

4. Sync invariants:
   - Local-first write, then queue outbox.
   - Push then pull.
   - Invalid events are quarantined (dead-letter), not silently applied.
   - Cross-store/account queue isolation is enforced.

5. UX/diagnostics invariants:
   - Local sale success remains success even when sync retry is needed.
   - Checkout diagnostics are logged locally (`checkout_diagnostics`) for speed/reliability benchmarks.

## Consequences
- Better determinism in reports/dashboard and lower risk of stock/accounting mismatch.
- Faster and safer checkout behavior in unstable networks.
- Simpler maintenance: one canonical sales create flow.
