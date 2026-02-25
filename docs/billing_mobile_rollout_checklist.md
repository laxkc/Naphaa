# Billing (Mobile-Only) Rollout Checklist

Last updated: 2026-02-25

Purpose:
- Validate the mobile-only billing + PDF + i18n flow before production rollout.
- Focus on offline-first behavior, invoice integrity, and PDF reliability.

## 1. Setup

- [ ] Install latest app build on target test device(s)
- [ ] Confirm backend is reachable (for login/sync baseline), but run offline scenarios too
- [ ] Login with a clean test account/store
- [ ] Ensure at least 2 products exist with stock and cost price
- [ ] Ensure billing settings are configured:
  - [ ] business name/address
  - [ ] PAN/VAT number
  - [ ] invoice prefix
  - [ ] VAT enabled/disabled mode
  - [ ] language (`en`/`ne`)

## 2. Draft + Issue (Offline)

- [ ] Turn internet OFF
- [ ] Create invoice draft with 2+ items
- [ ] Save draft successfully
- [ ] Reopen draft from invoice list
- [ ] Issue invoice offline successfully
- [ ] Confirm invoice number generated (`PREFIX-YEAR-#####`)
- [ ] Confirm issued invoice is no longer editable (items/totals)

## 3. Stock + Amount Integrity

- [ ] Confirm issuing invoice deducts product stock locally
- [ ] Confirm invoice totals match item sums (subtotal/tax/discount/total)
- [ ] Confirm VAT behavior:
  - [ ] VAT disabled
  - [ ] VAT enabled exclusive
  - [ ] VAT enabled inclusive
- [ ] Confirm no issue allowed for zero-item draft
- [ ] Confirm insufficient stock blocks issue

## 4. Payments + Status Transitions

- [ ] Record partial payment on issued invoice
- [ ] Confirm `paid_amount` and `balance_due` update correctly
- [ ] Confirm status remains `issued` until fully paid
- [ ] Record final payment
- [ ] Confirm status changes to `paid`
- [ ] Confirm overpayment is blocked

## 5. PDF Generation / Share / Print

- [ ] Issue invoice and generate PDF successfully
- [ ] Confirm `pdf_status = generated` behavior in UI (buttons visible)
- [ ] Share PDF via WhatsApp / Files
- [ ] Print PDF via OS print dialog (if printer/emulator supports)
- [ ] Delete/rename local PDF file manually (debug) and confirm app shows recoverable error
- [ ] Retry / Regenerate PDF works and updates path/status
- [ ] If PDF generation fails, invoice stays `issued` (not rolled back)

## 6. Restart Persistence

- [ ] Restart app completely
- [ ] Confirm invoice list still shows created invoices
- [ ] Open invoice detail and confirm:
  - [ ] items still present
  - [ ] payments still present
  - [ ] PDF actions still work for generated invoice

## 7. i18n / Formatting

- [ ] English UI labels look correct in billing screens
- [ ] Nepali UI labels look correct in billing screens
- [ ] NPR formatting uses Indian grouping (`en_IN` style)
- [ ] Invoice PDF uses snapshot labels/language for existing issued invoice
- [ ] Long line item names wrap in PDF without overlap
- [ ] Nepali text PDF rendering checked on device (font fallback/boxes issues)

## 8. Offline + Sync Compatibility (Current BP8 Behavior)

- [ ] Issue invoice and record payment while offline
- [ ] Open Sync Diagnostics and confirm invoice events exist in outbox with:
  - [ ] `entity=invoice` / `invoice_payment`
  - [ ] `status=deferred`
- [ ] Confirm no user-facing sync error due to invoice events (backend handlers not implemented yet)

## 9. Edge Cases

- [ ] Draft deletion works (draft only)
- [ ] Issued invoice deletion is blocked
- [ ] Overdue status updates when due date passes (manual date test / mock)
- [ ] 50+ line-item invoice PDF generates without crash
- [ ] Missing business fields (address/PAN/logo) do not break PDF generation

## 10. Release Notes / Support Prep

- [ ] Document known limitations:
  - no server-side invoice sync handlers yet (invoice events deferred)
  - Nepali PDF font rendering quality may depend on font embedding follow-up
  - no receipt-width template yet (A4 only)
- [ ] Support team knows where to find:
  - Invoice list/detail
  - Sync Diagnostics
  - Billing settings

## Pass Criteria (v1 Core)

Release is acceptable when all are true:
- [ ] No data corruption in invoice totals/payments/stock
- [ ] Invoice issue works offline reliably
- [ ] PDF generate/share/print succeeds on at least one real target device
- [ ] Billing screens remain stable after app restart
- [ ] No billing-related sync failure banners caused by invoice events
