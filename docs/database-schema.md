# SME Digital - Database Schema (Current)

Primary runtime DB: SQLite for local/dev, PostgreSQL-compatible model definitions.

## 1. users

- `id` (UUID, PK)
- `phone` (VARCHAR, unique)
- `password_hash` (TEXT)
- `created_at` (TIMESTAMP)

## 2. stores

- `id` (UUID, PK)
- `owner_user_id` (UUID, FK -> users.id, unique owner-store relation)
- `name` (VARCHAR)
- `locale_default` (VARCHAR, default `ne`)
- `currency` (VARCHAR, default `NPR`)
- `created_by`, `updated_by`, `device_id` (audit)
- `created_at`, `updated_at`

## 3. products

- `id` (UUID, PK)
- `store_id` (UUID, FK -> stores.id, indexed)
- `name` (VARCHAR)
- `sell_price`, `cost_price` (NUMERIC)
- `stock_qty` (NUMERIC)
- `low_stock_threshold` (NUMERIC)
- `is_active` (BOOLEAN)
- `is_deleted` (BOOLEAN, soft delete)
- `deleted_at` (TIMESTAMP)
- `created_by`, `updated_by`, `device_id` (audit)
- `created_at`, `updated_at`

## 4. customers

- `id` (UUID, PK)
- `store_id` (UUID, FK -> stores.id, indexed)
- `name`, `phone`
- `balance` (NUMERIC)
- `is_deleted` (BOOLEAN, soft delete)
- `deleted_at` (TIMESTAMP)
- `created_by`, `updated_by`, `device_id` (audit)
- `created_at`, `updated_at`

## 5. sales

- `id` (UUID, PK)
- `store_id` (UUID, FK -> stores.id, indexed)
- `sale_type` (`CASH|CREDIT|MIXED`)
- `payment_method` (nullable summary field)
- `customer_id` (nullable FK -> customers.id)
- `total_amount` (NUMERIC)
- `idempotency_key` (nullable)
- `created_by`, `updated_by`, `device_id`, `deleted_at`
- `created_at`, `updated_at`
- Unique: `(store_id, idempotency_key)`

## 6. sale_items

- `id` (UUID, PK)
- `sale_id` (UUID, FK -> sales.id, indexed)
- `product_id` (UUID, FK -> products.id)
- `qty`, `unit_price`, `line_total` (NUMERIC)

## 7. sale_payments

- `id` (UUID, PK)
- `sale_id` (UUID, FK -> sales.id, indexed)
- `method` (`CASH|QR|BANK|CREDIT`)
- `amount` (NUMERIC)
- `created_at`

## 8. sale_refunds

- `id` (UUID, PK)
- `store_id` (UUID, indexed)
- `sale_id` (UUID, FK -> sales.id, indexed)
- `amount` (NUMERIC)
- `reason` (TEXT, nullable)
- `created_by`, `device_id`
- `created_at`

## 9. sale_refund_items

- `id` (UUID, PK)
- `refund_id` (UUID, FK -> sale_refunds.id, indexed)
- `sale_id` (UUID, indexed)
- `product_id` (UUID, indexed)
- `qty`, `unit_price`, `line_total` (NUMERIC)

## 10. stock_movements

- `id` (UUID, PK)
- `store_id` (UUID, indexed)
- `product_id` (UUID, FK -> products.id, indexed)
- `movement_type` (`SALE_DEDUCTION|MANUAL_ADJUSTMENT|REFUND_RESTOCK`, indexed)
- `delta_qty`, `balance_after` (NUMERIC)
- `reason` (TEXT, nullable)
- `reference_type`, `reference_id`
- `created_by`, `device_id`
- `created_at`

## 11. customer_payments

- `id` (UUID, PK)
- `store_id` (UUID, FK -> stores.id, indexed)
- `customer_id` (UUID, FK -> customers.id, indexed)
- `method` (default `CASH`)
- `amount` (NUMERIC)
- `note` (TEXT, nullable)
- `created_by`, `device_id`
- `created_at`

## 12. expenses

- `id` (UUID, PK)
- `store_id` (UUID, FK -> stores.id, indexed)
- `category` (`RENT|TRANSPORT|SALARY|UTILITIES|OTHER`)
- `amount` (NUMERIC)
- `note` (TEXT, nullable)
- `created_by`, `updated_by`, `device_id`
- `created_at`, `updated_at`

## 13. devices

- `device_id` (VARCHAR, PK)
- `owner_user_id` (UUID, FK -> users.id, indexed)
- `platform`, `device_model`, `app_version`
- `registered_at`, `last_seen_at`

## 14. sync_events

- `id` (UUID, PK)
- `store_id` (UUID, indexed)
- `entity`, `operation`
- `fingerprint` (indexed)
- `payload` (JSON)
- `created_at`
- Unique: `(store_id, fingerprint)`

## 15. revoked_tokens

- `id` (UUID, PK)
- `token_hash` (SHA256, unique, indexed)
- `token_type` (default `refresh`)
- `expires_at`
- `created_at`

## Integrity rules (implemented)

- Stock cannot go below zero.
- Credit portion of sales updates customer balance.
- Customer payment cannot exceed current balance.
- Product delete is soft-delete and blocked if linked sale items exist.
- Customer delete is soft-delete and blocked if outstanding balance exists.
- Sales retries with same idempotency key do not duplicate records.
