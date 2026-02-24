# API Contract Policy

Status date: February 19, 2026

## 1. Definition

API contract is the strict backend-mobile agreement for:

- Request schema
- Response schema
- Field names
- Enum values
- Error structure
- Versioning rules

## 2. Source of Truth

Single source of truth is FastAPI OpenAPI output:

- Runtime: `/openapi.json`
- Versioned snapshot in repo: `/Users/laxmankc/Startup/SME/sme-digital/docs/openapi.v1.json`

Mobile integration must follow this contract only.

## 3. Contract Stability Rules

1. No breaking field rename/removal inside `/api/v1`.
2. Additive changes are allowed (`new optional fields`, `new endpoints`).
3. Enum changes in v1 must be backward compatible.
4. Breaking changes require `/api/v2`.

## 4. Error Contract

All business/API errors must keep this shape:

```json
{
  "detail": {
    "code": "MACHINE_CODE",
    "detail": "Human readable message"
  }
}
```

Mobile must map user-facing messages from `detail.code`.

## 5. Release Workflow

Before backend release:

1. Regenerate OpenAPI snapshot:

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/backend
.venv/bin/python scripts/export_openapi.py
```

2. Review diff of `/Users/laxmankc/Startup/SME/sme-digital/docs/openapi.v1.json`.
3. Mark change type:
- patch (non-breaking fix)
- minor (additive endpoints/fields)
- major (breaking, requires new API version)
4. Share contract diff with mobile team before merge/release.

## 6. Flutter Integration Pattern

Backend (FastAPI)
-> OpenAPI spec
-> Flutter models/client generation or strict manual mapping
-> repository layer
-> UI

Never let Flutter guess request or response structures.
