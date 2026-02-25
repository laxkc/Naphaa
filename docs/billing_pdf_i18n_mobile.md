# Billing + PDF + i18n (Mobile-Only, Offline-First) — Full Specification (v1)

## 0. Scope
### In Scope (v1)

- Create invoices offline
- Generate PDF on mobile
- Support Nepali + English (i18n) for UI and invoice PDF
- Per-business settings (store account):
  - language, currency, VAT, invoice prefix, numbering, terms, logo, address, PAN/VAT
- Share/print PDF (WhatsApp, Files, Print)
- Sync-ready event design (even if backend storage later)

### Out of Scope (v1)

- Cloud PDF storage / URL hosting
- Server-generated PDF
- Bank reconciliation, eSewa auto-match
- Multi-device invoice sequence authority (we’ll design future-proof hooks)

## 1. Key Principles

- Offline-first: all billing works without internet
- Immutable issued invoices: once issued, totals/items cannot change
- Business-scoped: invoices belong to a business/store tenant
- i18n everywhere: UI + PDF + number/date formatting
- Future-proof: event payloads ready for later server canonicalization

## 2. Entities & Data Model (SQLite)
### 2.1 business table (existing + add fields)

- id (uuid)
- name
- address_line1, address_line2, city
- phone, email
- pan_vat_number (string)
- logo_path (local file path)
- language (enum: ne, en)
- currency_code (e.g., NPR)
- fiscal_calendar (enum: BS, AD) — for display
- vat_enabled (bool)
- vat_rate (decimal) default e.g. 13
- tax_mode (enum: exclusive, inclusive)
- invoice_prefix (string, e.g., INV, KTM, BH) (optional)
- invoice_terms_default (string)
- invoice_footer_default (string)

### 2.2 invoices table (new)

- id (uuid)
- business_id (uuid, indexed)
- customer_id (uuid, nullable for walk-in)
- invoice_number (string, unique per business)
- status (enum: draft, issued, paid, overdue, cancelled)
- issue_date (datetime)
- due_date (datetime, nullable)
- currency_code (string snapshot)
- fiscal_calendar_snapshot (BS/AD snapshot)
- subtotal (decimal)
- discount_amount (decimal)
- tax_amount (decimal)
- total (decimal)
- paid_amount (decimal)
- balance_due (decimal)
- payment_method_summary (string: cash, qr, bank, mixed, credit)
- notes (text)
- pdf_path (text, nullable)
- pdf_status (enum: none, generated, failed)
- created_at, updated_at

Snapshots matter: store currency/calendar/tax mode snapshot on invoice so old invoices remain consistent even if settings change later.

### 2.3 invoice_items table (new)

- id (uuid)
- invoice_id (uuid, indexed)
- product_id (uuid, nullable)
- product_name_snapshot (text)
- unit_snapshot (text) (e.g., pcs, kg)
- quantity (decimal)
- unit_price (decimal)
- discount (decimal)
- tax_rate_snapshot (decimal)
- line_subtotal (decimal)
- line_tax (decimal)
- line_total (decimal)

### 2.4 invoice_payments table (optional v1, recommended)

If you already have customer payments, you can reuse; but invoice-scoped helps.

- id (uuid)
- invoice_id
- amount
- method (cash/qr/bank)
- paid_at
- note

### 2.5 invoice_sequence table (new)

Per business and per year, local-only for now.

- business_id
- year_key (string: 2026 or 2082 depending on chosen display)
- last_seq (integer)

Unique constraint: (business_id, year_key)

## 3. Billing Flow (Offline)
### 3.1 Draft Invoice

- User creates invoice and adds items
- App computes totals locally
- Save invoice with status=draft
- No PDF required yet

### 3.2 Issue Invoice (Critical Event)

When user taps Issue:

Validate:
- has at least 1 item
- stock (if stock tracking enabled)

Generate invoice_number (Section 4)

Freeze values:
- items snapshot already stored
- totals written and locked

Write financial effects:
- stock deduction
- ledger entry

Set status=issued

Generate PDF locally

Save pdf_path, pdf_status

Allow share/print

### 3.3 Payments (Cash / Partial / Credit)

- Cash sale: set paid_amount=total, balance_due=0, status=paid
- Credit sale: set paid_amount=0, balance_due=total, status=issued
- Partial: update paid_amount, balance_due
- If balance_due==0, status becomes paid

### 3.4 Overdue

Local check on app open or daily timer:

if status in (issued, overdue) and due_date < now and balance_due>0
-> set status=overdue

## 4. Invoice Numbering (Mobile-Only, Business-Scoped)
### 4.1 Requirements

- Unique per business
- Sequential (for trust)
- Works offline
- Future-friendly

### 4.2 Format

Default:
`{PREFIX}-{YEAR}-{SEQ_PAD5}`

Examples:

- `INV-2026-00012`
- `KTM-2026-00001`

PREFIX comes from business settings.

### 4.3 Local Generation Algorithm

On issue:

- Determine year_key:
  - If business display calendar = AD -> 2026
  - If BS -> 2082 (display only; internal can still store AD date)
- Begin SQLite transaction
- Read invoice_sequence row for (business_id, year_key)
- Increment last_seq
- Compose invoice_number
- Save back to sequence row
- Ensure uniqueness constraint in invoices table
- Commit

Note: later multi-device you add device prefix or server numbering. For now, mobile-only is safe.

## 5. VAT / Tax Computation (Nepal-friendly)
### 5.1 Settings

- vat_enabled: true/false
- vat_rate: default 13%
- tax_mode: exclusive or inclusive

### 5.2 Item Calculations

For each item:

- base = quantity * unit_price
- discount applied per item or invoice-level (v1 choose invoice-level simple)

if tax_mode = exclusive:

- line_tax = (base - discount) * vat_rate
- line_total = (base - discount) + line_tax

if inclusive:

- line_total = base - discount
- line_tax = line_total * (vat_rate / (1 + vat_rate))
- line_subtotal = line_total - line_tax

Invoice totals = sum(line_subtotal), sum(line_tax), etc.

### 5.3 Display

- If Nepali locale, show VAT label as “भ्याट”
- Include PAN/VAT number in header if set

## 6. i18n Plan (UI + PDF)
### 6.1 Language Selection

Per business (store account):

- business.language = ne or en

All invoice UI and PDF uses business language, not device language.

### 6.2 Translation Keys (Examples)

- invoice.title = “Invoice” / “बिल”
- invoice.no = “Invoice No” / “बिल नं”
- date = “Date” / “मिति”
- due_date = “Due Date” / “बुझाउने मिति”
- customer = “Customer” / “ग्राहक”
- item = “Item” / “सामान”
- qty = “Qty” / “परिमाण”
- rate = “Rate” / “दर”
- subtotal = “Subtotal” / “जम्मा”
- vat = “VAT” / “भ्याट”
- discount = “Discount” / “छुट”
- total = “Total” / “कुल जम्मा”
- paid = “Paid” / “तिरेको”
- balance = “Balance” / “बाकी”

### 6.3 Number Formatting (Important)

NPR formatting (`1,23,456` style) is Indian grouping; Flutter may not default.
v1: use `intl` formatting with `en_IN` for NPR style grouping.

Optional Nepali digits:

- v1 keep English digits (simpler)
- v1.1 add toggle: Nepali digits (०१२३४५६७८९)

### 6.4 Date Formatting

Store dates internally as AD ISO timestamps.

Display:

- If business calendar = AD -> YYYY-MM-DD or local format
- If business calendar = BS -> show BS date (requires BS conversion library)

v1 suggestion: show AD date only + allow BS in later v1.1 if you don’t already have BS conversion.

## 7. Mobile PDF Generation
### 7.1 Packages

- pdf
- printing
- path_provider
- share_plus

### 7.2 PDF Generation Policy

- Generate PDF at issue time
- If generation fails:
  - invoice stays issued
  - pdf_status = failed
  - “Retry PDF” button available

### 7.3 Local File Storage

- Directory: `app_documents/invoices/{business_id}/`
- File: `{invoice_number}.pdf`
- Save pdf_path in invoice record

### 7.4 Template Layout (A4 & Receipt)

Support 2 formats (optional):

- A4 standard invoice (primary)
- 80mm receipt (later)

A4 layout:

- Header: logo + business info
- Invoice info block
- Customer block
- Items table
- Totals summary
- Notes + terms
- Footer

### 7.5 Bilingual Invoice (Optional)

Two modes:

- Single language (based on business.language) — v1
- Bilingual (Nepali + English on same PDF) — v1.2

## 8. Sync Compatibility (Even If Cloud Later)

Even if you don’t upload PDFs now, keep sync events ready.

New outbox ops:

- invoice_issue
- invoice_payment
- invoice_cancel

Payload includes:

- invoice_id
- invoice_number
- totals
- items snapshot
- issue_date
- due_date
- tax config snapshot
- pdf_hash (optional, later)

Later when backend exists:

- send invoice data
- optionally upload PDF file
- server stores canonical invoice + pdf_url

No refactor needed.

## 9. UI Screens
### 9.1 Invoice Create (Draft)

- select customer
- add items (quick add)
- show running totals
- save draft

### 9.2 Invoice Detail

- status badge
- invoice number
- PDF actions:
  - View PDF
  - Share PDF
  - Print
  - Regenerate PDF (if failed)
- Payment actions:
  - Record payment
  - Mark paid (if cash)

### 9.3 Invoice List

Filters:

- status
- date range
- customer
- amount range (optional)

Sort:

- newest first

## 10. Integrity Rules (Non-negotiable)

- Issued invoices cannot be edited (items/totals/tax)
- Cancellation requires reason
- Paid invoice cannot be cancelled (unless you add credit note system later)
- No deletion of issued invoices (only draft can be deleted)
- Ledger entries must match invoice totals

## 11. Testing Checklist
### Offline Tests

- Create draft, issue, generate PDF offline
- Restart app → invoice + PDF still accessible
- Share PDF works offline

### Data Consistency

- Issued invoice totals match ledger
- Stock updated correctly
- Payment updates correct status

### i18n Tests

- Business language switches invoice labels correctly
- Currency formatting correct
- Long Nepali text wraps properly in PDF

### PDF Tests

- PDF generation stable with 50+ line items
- Logo missing fallback
- Retry PDF works

