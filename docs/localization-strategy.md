# SME Digital - Localization Strategy

Status date: February 19, 2026

## 1. Principles

- Backend remains language-neutral.
- Mobile app performs translation and formatting.
- Business data is stored as raw structured values (not translated strings).

## 2. Supported Locales (MVP)

- Nepali (`ne`)
- English (`en`)

Default behavior:

- Store locale defaults to `ne` unless explicitly set.
- Currency defaults to `NPR`.

## 3. Mobile Localization

### 3.1 Translation assets

- Use ARB files in `lib/l10n/`
- Example files:
  - `app_en.arb`
  - `app_ne.arb`

Rules:

- No hardcoded UI labels in widgets.
- Error labels shown to users should be localized from API error codes.

### 3.2 Formatting

- Currency: NPR display (e.g., `Rs 10,000`)
- Number formatting: locale-aware separators
- Dates: AD format for MVP

### 3.3 Offline behavior

- Translation resources must be bundled with app.
- UI localization must work with zero network.

## 4. Backend Localization Contract

Backend responsibilities:

- Accept `Accept-Language` optionally.
- Persist store defaults (`locale_default`, `currency`).
- Return enum/code values for client-side localization.

Example:

- API returns `"category": "RENT"`
- Mobile maps to localized label.

## 5. API Error Localization Strategy

Current API error shape:

```json
{
  "detail": {
    "code": "INSUFFICIENT_STOCK",
    "detail": "Stock cannot go below zero"
  }
}
```

Mobile behavior:

- Primary mapping by `detail.code`
- Fallback to `detail.detail` when localized mapping is unavailable

## 6. Terminology Guidelines

Use plain business language in UI:

- Sales
- Credit
- Expense
- Profit
- Stock

Avoid heavy accounting jargon for MVP users.

## 7. Future Extensions

- Bikram Sambat (BS) date support
- Region-specific number format preferences
- SMS/notification language preference
