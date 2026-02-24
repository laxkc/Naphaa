# SME Digital API Specification (v1)

Status date: February 19, 2026

Base URL: `/api/v1`

Health endpoint: `GET /health`

Contract governance policy: `/Users/laxmankc/Startup/SME/sme-digital/docs/api-contract.md`

## 1. Auth and Headers

- Bearer auth: `Authorization: Bearer <access_token>`
- Optional write audit header: `X-Device-Id`
- Sale idempotency header: `Idempotency-Key`

## 2. Standard Error Shape

```json
{
  "detail": {
    "code": "MACHINE_CODE",
    "detail": "Human readable message"
  }
}
```

## 3. Standard Pagination Shape

```json
{
  "items": [],
  "total": 120,
  "page": 1,
  "page_size": 20
}
```

## 4. Endpoint Index

### Health

- `GET /health`

### Auth

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `GET /auth/me`
- `POST /auth/logout`
- `POST /auth/change-password`
- `POST /auth/forgot-password` (pilot stub)
- `POST /auth/reset-password` (pilot stub)

### Store

- `POST /stores`
- `GET /stores/me`
- `PATCH /stores/{store_id}`

### Products

- `POST /products`
- `GET /products` (pagination + search + sort)
- `GET /products/{product_id}`
- `PATCH /products/{product_id}`
- `DELETE /products/{product_id}` (soft delete)
- `POST /products/{product_id}/adjust-stock`
- `GET /products/{product_id}/stock-history` (paginated)

### Customers

- `POST /customers`
- `GET /customers` (pagination + search + sort)
- `GET /customers/{customer_id}`
- `PATCH /customers/{customer_id}`
- `DELETE /customers/{customer_id}` (soft delete)
- `POST /customers/{customer_id}/payments`
- `GET /customers/{customer_id}/ledger` (paginated)

### Sales

- `POST /sales`
- `GET /sales`
- `GET /sales/{sale_id}`
- `POST /sales/{sale_id}/refund`

### Expenses

- `POST /expenses`
- `GET /expenses`
- `GET /expenses/{expense_id}`

### Reports

- `GET /reports/summary`
- `GET /reports/low-stock`
- `GET /reports/cashbook`
- `GET /reports/top-products`

### Export

- `GET /exports/full`

### Devices

- `POST /devices/register`
- `GET /devices`

### Sync

- `POST /sync/push`
- `GET /sync/pull`
- `GET /sync/status`

## 5. Core Request/Response Schemas

### 5.1 Token Pair

```json
{
  "access_token": "jwt",
  "refresh_token": "jwt",
  "token_type": "bearer"
}
```

### 5.2 Sale Create

Enums:

- `sale_type`: `CASH | CREDIT | MIXED`
- payment method (single and split line): `CASH | QR | BANK | CREDIT`

Simple payment mode:

```json
{
  "sale_type": "CASH",
  "payment_method": "QR",
  "customer_id": null,
  "items": [
    { "product_id": "uuid", "qty": 1, "unit_price": 25 }
  ]
}
```

Split payment mode:

```json
{
  "sale_type": "MIXED",
  "customer_id": "uuid",
  "items": [
    { "product_id": "uuid", "qty": 1, "unit_price": 25 },
    { "product_id": "uuid", "qty": 1, "unit_price": 80 }
  ],
  "payments": [
    { "method": "CASH", "amount": 50 },
    { "method": "CREDIT", "amount": 55 }
  ]
}
```

Business rules:

- `items` required and non-empty
- `qty > 0` and `unit_price > 0`
- Split payment sum must equal sale total
- If credit component exists, `customer_id` required
- Stock cannot go negative
- Credit amount increases customer balance
- Idempotency key prevents duplicate sale on retries

### 5.3 Sale Response

```json
{
  "id": "uuid",
  "store_id": "uuid",
  "sale_type": "MIXED",
  "payment_method": "MIXED",
  "customer_id": "uuid",
  "total_amount": "105.00",
  "created_at": "...",
  "updated_at": "...",
  "items": [],
  "payments": []
}
```

### 5.4 Refund Request

```json
{
  "reason": "Return noodles",
  "items": [
    { "product_id": "uuid", "qty": 1 }
  ]
}
```

`items[]` also supports `sale_item_id` as alternative reference.

### 5.5 Ledger Response

```json
{
  "items": [
    {
      "type": "SALE",
      "ref_id": "sale_uuid",
      "amount": "105.00",
      "running_balance": "105.00",
      "note": null,
      "created_at": "..."
    }
  ],
  "total": "1",
  "page": 1,
  "page_size": 20
}
```

### 5.6 Stock History Response

```json
{
  "items": [
    {
      "type": "SALE_DEDUCTION",
      "ref_id": "sale_uuid",
      "delta_qty": "-1.00",
      "created_at": "..."
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

### 5.7 Cashbook Report Response

```json
{
  "cash_total": "12000.00",
  "qr_total": "8000.00",
  "bank_total": "0.00",
  "credit_total": "3000.00"
}
```

### 5.8 Sync Status Response

```json
{
  "server_time": "...",
  "last_event_id": "uuid",
  "recommended_pull_since": "..."
}
```

## 6. Filters and Query Parameters

- Products: `search`, `sort`, `order`, `page`, `page_size`
- Customers: `search`, `sort`, `order`, `page`, `page_size`
- Sales: `from`, `to`, `search`, `page`, `page_size`
- Expenses: `from`, `to`, `search`, `page`, `page_size`
- Ledger: `from`, `to`, `page`, `page_size`
- Stock history: `page`, `page_size`
- Top products: `limit`

## 7. Notes

- Product/customer delete operations are soft deletes.
- Sales are treated as immutable transactions; correction is via refund endpoint.
- Full OpenAPI details are available at `/openapi.json` and `/docs`.
