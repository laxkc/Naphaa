# SME Digital SPI Integration Summary

This is a quick integration map. Full request/response schemas are in:

- `/Users/laxmankc/Startup/SME/sme-digital/docs/api-spec.md`

## Base

- Health: `GET /health`
- API base: `/api/v1`

## High-priority integration endpoints

### Auth

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/change-password`

### Core operations

- `POST /api/v1/sales` (supports idempotency and split payments)
- `POST /api/v1/sales/{sale_id}/refund`
- `POST /api/v1/products/{product_id}/adjust-stock`
- `POST /api/v1/customers/{customer_id}/payments`

### Trust and reporting

- `GET /api/v1/customers/{customer_id}/ledger`
- `GET /api/v1/products/{product_id}/stock-history`
- `GET /api/v1/reports/summary`
- `GET /api/v1/reports/low-stock`
- `GET /api/v1/reports/cashbook`
- `GET /api/v1/reports/top-products`
- `GET /api/v1/exports/full`

### Sync and devices

- `POST /api/v1/devices/register`
- `GET /api/v1/devices`
- `POST /api/v1/sync/push`
- `GET /api/v1/sync/pull`
- `GET /api/v1/sync/status`

## Integration requirements

- Auth header: `Authorization: Bearer <access_token>`
- Sales retries: send `Idempotency-Key` for safe mobile retries.
- Write operations: optionally send `X-Device-Id` for auditability.
- Error handling: parse machine code from `detail.code`.
