# SME Digital - Mobile Design (Flutter)

Status date: February 19, 2026

## 1. Goals

- Fast daily entry for kirana workflows
- Offline-first reliability on Android and iOS
- Clear business state (loading/success/error)

## 2. App Structure

Recommended feature-first layout:

```text
lib/
  core/
    network/
    storage/
    sync/
    theme/
  features/
    auth/
    dashboard/
    products/
    customers/
    sales/
    expenses/
    reports/
  shared/
  l10n/
```

## 3. State Management

- Riverpod for state + dependency management
- Async states must always expose:
  - loading
  - data
  - error

## 4. Data and Offline Model

### 4.1 Local tables (mirror backend domains)

- products
- customers
- sales
- sale_items
- sale_payments
- sale_refunds
- sale_refund_items
- customer_payments
- stock_movements
- expenses
- sync_queue

### 4.2 Write flow

1. Validate input
2. Save local change
3. Enqueue sync event
4. Attempt background sync
5. Reconcile response

## 5. Screen Requirements

### 5.1 Auth

Login screen:

- Phone + password
- Forgot password entry point
- Sign in CTA
- Switch to signup

Signup screen:

- Business name + phone + password
- Create account CTA
- Switch to login

Validation:

- Phone length and format
- Password minimum length
- Non-empty business name for signup

### 5.2 Dashboard

Display professional but simple cards:

- Today sales
- Credit outstanding
- Expense total
- Low stock count
- Quick actions (add sale, add product, add expense)

### 5.3 Sales

Must support:

- Product search and quick add
- Quantity and unit price editing
- Payment mode: cash/QR/bank/credit/mixed
- Split payment rows for mixed sales
- Customer selection for credit component
- Save with loading/disable state

### 5.4 Customers

- Customer list with search
- Ledger timeline (sale/payment/refund)
- Payment collection flow

### 5.5 Inventory

- Product list and search
- Manual stock adjustment
- Stock history view

## 6. Error Handling UX

- Never show raw HTTP stack traces
- Map API `detail.code` to user-friendly localized messages
- For 401 on login: show invalid credentials message
- For sync failures: queue remains and retry action is visible

## 7. Performance Targets

- App cold start under 3 seconds (typical device)
- Sale entry path under 10 seconds
- Dashboard visible quickly with cached data first

## 8. Security

- Store access/refresh tokens in secure storage
- Clear tokens and local sensitive auth state on logout
- Never store plaintext passwords

## 9. Testing Expectations

- Unit tests for calculators/validators
- Widget tests for auth/sales/dashboard error states
- Integration tests for offline->online sync and mixed payment sale flow
