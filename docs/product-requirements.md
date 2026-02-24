# SME Digital - Product Requirements (MVP)

Status date: February 19, 2026

## 1. Objective

Deliver a mobile-first SME operations app for Nepal retail shops that is fast, reliable, and offline-safe.

## 2. Primary Users

- Grocery/kirana shop owners in Nepal
- Users with low to medium technical literacy
- Android and iOS users

## 3. Core MVP Outcomes

1. Daily sales capture is faster than paper
2. Stock remains accurate after sales/refunds/adjustments
3. Credit tracking is trusted by shop owners
4. Offline usage does not lose transactions

## 4. Functional Scope (MVP)

1. Auth and store setup
- Login/signup and token-based access
- Single-store ownership for MVP

2. Sales and payments
- Cash, QR, bank, credit, and mixed split payments
- Idempotent sale creation for retry safety
- Refund/return support

3. Inventory
- Product CRUD
- Manual stock adjustment
- Stock movement history
- Low stock reporting

4. Customers and credit
- Customer CRUD with soft delete
- Customer payments
- Customer ledger (sales/payments/refunds + running balance)

5. Expenses and reporting
- Expense tracking
- Summary, cashbook, top-products, low-stock reports

6. Sync and device support
- Offline event queue
- Sync push/pull/status
- Device registration for operational traceability

7. Export
- Full JSON export of store operational data

## 5. Non-Goals (Current MVP)

- Multi-user roles/RBAC
- Subscription billing enforcement
- Supplier/purchase order management
- File upload pipeline (receipts/logos)
- OTP-based forgot/reset password flow

## 6. Quality Requirements

- Sale entry flow under 10 seconds on common devices
- No negative stock conditions
- No duplicate sales under client retries
- Clear loading/success/failure states in mobile UI

## 7. Success Metrics

- Pilot stores perform daily transactions in app
- Credit and stock mismatch complaints are minimal
- Offline-to-online sync completes without duplicates
- Users report app is faster and easier than notebook workflow
