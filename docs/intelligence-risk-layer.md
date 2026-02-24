# Intelligence + Risk Layer
## Product + Technical Specification (v1)

## Goal

Turn your app from a recording tool (ledger + inventory) into a decision tool (insights + risk control) by adding:

- Business Intelligence (profit, trends, stock health, cash outlook)
- Credit Risk (who will pay late, what is overdue, what needs follow-up)

## Non-Goals (v1)

- Full accounting double-entry system (you already have ledger v1; keep it simple)
- Payroll, full VAT filing, bank reconciliation automation
- ML-heavy models (start rule-based; upgrade later)

## 1. Core Concepts

### 1.1 Intelligence vs Risk

- Intelligence: What is happening in the business and why? (profit, trends, inventory movement)
- Risk: What is likely to go wrong soon? (late payments, cash shortage, stockouts)

### 1.2 Design Principles

- Explainable (SMEs trust what they understand)
- Actionable (every insight suggests an action)
- Fast (computed locally + verified on server)
- Offline-first (insights available even without internet)
- Consistent (insight numbers match ledger totals)

## 2. User-Facing Features

### 2.1 Business Health Dashboard (New)

A new top-level screen or dashboard tab: `Business Health`

Sections:

- Profit Snapshot
  - Gross sales (selected period)
  - Expenses (selected period)
  - Estimated profit (already present, upgrade accuracy)
  - Profit margin %
- Cash Outlook (Simple)
  - Expected incoming (from outstanding credit likely to be collected soon)
  - Expected outgoing (based on recurring expenses pattern)
  - Cash risk level: `Low / Medium / High` (with explanation)
- Credit Risk Summary
  - Total outstanding
  - Overdue amount
  - Number of overdue customers
  - High risk customers (top 5)
- Stock Health
  - Low stock items
  - Dead stock items (no movement in X days)
  - Fast movers (top items)
- Alerts feed
  - Actionable items (overdue reminders, dead stock, margin drop, etc.)

### 2.2 Credit Aging Report (Must-have)

Break outstanding credit by age bucket:

- 0-7 days
- 8-30 days
- 31-60 days
- 60+ days

Outputs:

- Total per bucket
- Per customer breakdown
- Filters: only overdue, only high-risk

### 2.3 Customer Risk Score (v1 Rule-Based)

Each customer gets a risk score + color:

- Green (Good payer)
- Yellow (Medium risk)
- Red (High risk)

Shown in:

- Customer list (badge)
- Customer detail page
- Credit report list
- Sales flow (credit warning)

Risk inputs (explainable):

- Days overdue (current oldest unpaid)
- Average days to pay (historical)
- On-time rate
- Outstanding amount spike vs normal
- Payment frequency

Example explanation UI:

- Risk: RED
- Overdue: 45 days (high)
- On-time rate: 20% (low)
- Outstanding: Rs 25,000 (above normal)

### 2.4 Credit Limits + Safe Credit (Optional v1)

Customer profile additions:

- `credit_limit` (Rs)
- `soft_limit_warning` (boolean)

Credit sale behavior:

- If `outstanding + new sale > limit`: warn or block (business setting)

### 2.5 Profit by Product (v1)

Report outputs:

- Revenue per product
- Quantity sold
- Estimated profit (requires cost_price)
- Profit margin %

v1 approach:

- Use `products.cost_price`
- `Profit = (sale_price - cost_price) * qty`

### 2.6 Dead Stock Detection (v1)

Dead stock =

- `stock > 0`
- No sale movement in `X` days (default 30)

Outputs:

- Dead stock list
- Value locked in dead stock (`stock_qty * cost_price`)

### 2.7 Expense Spike Alerts (v1)

Detect unusual expense increases by category:

- Compare current week vs last 4-week average
- Trigger if `> 30%` increase and `> threshold amount`

## 3. Data Model Additions

### 3.1 Tables / Fields (Backend + Local SQLite)

`products`

- `cost_price` (recommended)
- `last_movement_at` (cached)
- `dead_stock_days_override` (optional)

`sales`

- `due_date` (optional)
- `is_credit` (already implied)
- `paid_amount` (already tracked via payments)

`customer_metrics` (new cached table)

- `customer_id`
- `outstanding_amount`
- `oldest_due_days`
- `avg_days_to_pay`
- `on_time_rate`
- `payment_frequency_30d`
- `risk_score` (0-100)
- `risk_level` (green/yellow/red)
- `computed_at`
- `version`

`product_metrics` (new cached table)

- `product_id`
- `qty_sold_7d` / `qty_sold_30d`
- `revenue_30d`
- `profit_30d`
- `last_sale_at`
- `dead_stock` (bool)
- `computed_at`

`business_metrics` (new cached table)

- `business_id`
- `period_start`, `period_end`
- `sales_total`
- `expenses_total`
- `profit_est`
- `profit_margin`
- `outstanding_total`
- `overdue_total`
- `cash_risk_level`
- `computed_at`

`alerts` (new table)

- `alert_id`
- `type` (`credit_overdue`, `low_stock`, `dead_stock`, `expense_spike`, `margin_drop`)
- `entity_type` (`customer`/`product`/`business`)
- `entity_id`
- `severity` (`info`/`warn`/`critical`)
- `title`
- `body`
- `action_type` (`send_reminder`, `open_customer`, `open_product`, `view_report`)
- `created_at`
- `resolved_at` (nullable)

## 4. Algorithms (v1: rule-based, deterministic)

### 4.1 Credit Aging Bucket Computation

For each unpaid invoice/sale:

- `age_days = today - sale_date` (or `due_date` if set)
- `outstanding = total - paid`

Buckets:

- 0-7
- 8-30
- 31-60
- 60+

Important:

- Use timezone-safe date boundaries (same approach as existing sales/report fixes)

### 4.2 Average Days to Pay

For each fully paid sale:

- `days_to_pay = paid_date - sale_date`
- `avg_days_to_pay = mean(last N=20 payments)`

Fallback:

- default 14 days if insufficient data

### 4.3 On-Time Rate

Define on-time as:

- paid within 7 days OR before `due_date` (if set)

Formula:

- `on_time_rate = on_time_count / total_paid_sales_count` (rolling 90 days)

### 4.4 Risk Score Formula (0-100)

Let:

- `A = clamp(oldest_due_days / 60, 0..1)`
- `B = clamp(avg_days_to_pay / 30, 0..1)`
- `C = 1 - on_time_rate`
- `D = clamp(outstanding_amount / (avg_invoice_amount * 3), 0..1)`

Formula:

- `risk_score = 100 * (0.40A + 0.25B + 0.25C + 0.10D)`

Risk level:

- Green: `< 35`
- Yellow: `35-65`
- Red: `> 65`

UI should show contributing factors A/B/C/D.

### 4.5 Dead Stock

- `dead_stock = stock_qty > 0 AND (today - last_sale_at > X days)`
- Default `X = 30` (configurable)

### 4.6 Expense Spike

For each expense category:

- `avg_4w = average weekly spend (last 4 weeks)`
- `current_week = spend this week`

Spike if:

- `current_week > avg_4w * 1.3`
- and `current_week > min_threshold`

## 5. Offline-First + Sync Integration

### 5.1 Compute Location Strategy

- Local compute first for instant UI
- Server compute for canonical + cross-device consistency
- Sync computed metrics as cached tables

Pattern:

1. App computes metrics after each local change
2. Metrics are written to local metrics tables
3. Outbox sync sends raw events only
4. Server recomputes metrics and returns authoritative metrics in `/sync/pull`

### 5.2 Trigger Points

Recompute metrics on:

- Sale create/update
- Payment recorded
- Expense create
- Stock adjustment
- Product price/cost changes

### 5.3 Sync APIs

- `GET /metrics/business?period=...`
- `GET /metrics/customers?period=...`
- `GET /metrics/products?period=...`
- `GET /alerts?status=open`

Note:

- Metrics can also be delivered via `/sync/pull` events for tighter offline-first behavior.

## 6. UI/UX Requirements

### 6.1 Explainability

Every risk score must show:

- why
- what changed
- what action

### 6.2 Action Buttons

Every insight should have CTA:

- Send reminder
- Call customer
- Open credit report
- Adjust stock
- View dead stock list

### 6.3 Minimal Cognitive Load

- 3 colors (green/yellow/red)
- Short titles
- One-line explanation
- Expand for details

## 7. Security & Privacy

- Risk scores are internal analytics, not shared externally
- Role-based access: staff can view but not change credit limits (optional)
- Audit log metric changes (server side)

## 8. Testing Plan

Unit tests:

- bucket logic
- score computation
- date boundary correctness
- expense spike trigger

Integration tests:

- local compute vs server compute consistency
- sync pull overwrites cache properly
- multi-device conflict scenarios

Regression tests:

- metrics totals match ledger totals
- timezone-safe report filtering

## 9. Rollout Plan (Practical)

### v1 (2-4 weeks)

- Credit aging report
- Customer risk score + badge
- Alerts feed (credit overdue + dead stock + low stock)
- Basic profit per product (requires `cost_price`)

### v1.1

- Cash outlook
- Expense spikes
- Credit limits

### v2

- ML models (optional)
- Payment reconciliation automation
- Financing / loan readiness

## 10. KPIs (How You Know It Worked)

- % of users who open Business Health dashboard daily
- reminders sent per week
- reduction in overdue days
- reduction in dead stock items
- increase in repeat usage of reports

## Appendix A: Minimum Data Needed

To launch Intelligence + Risk Layer:

- sales (amount, date, customer, payment status)
- payments (amount, date, customer)
- expenses (amount, date, category)
- products (stock_qty, last movement, cost_price)

You already have most of these.
