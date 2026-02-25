# Offline-First Test & Rollout Checklist (Phase 8)

Last updated: 2026-02-24

## Automated Checks (Current)

- Mobile static analysis: `flutter analyze`
- Backend import smoke check: `./.venv/bin/python -c "import app.main; print('ok')"`
- Backend sync/intelligence regression examples:
  - `uv run pytest backend/tests/unit/test_intelligence_service.py backend/tests/api/test_products_customers_sales_expenses_reports.py -q`
- Mobile sync/intelligence regression examples:
  - `flutter test mobile/test/integration/sync_service_test.dart mobile/test/integration/sync_coordinator_test.dart mobile/test/integration/intelligence_ui_test.dart mobile/test/integration/intelligence_providers_test.dart`

## Manual E2E Scenarios (Required Before Release)

- [ ] Offline create product -> reconnect -> backend product list shows product
- [ ] Offline create customer -> reconnect -> backend customer list shows customer
- [ ] Offline create expense -> reconnect -> backend reports include expense
- [ ] Offline create sale -> reconnect -> backend sales/reports reflect sale
- [ ] Token expiry during sync -> refresh token -> sync resumes
- [ ] Sync failure (network drop mid-sync) -> retry backoff -> eventual success
- [ ] Delete customer/product on one side -> other side receives tombstone sync

## Regression Checks

- [ ] Dashboard totals match local sales/expenses after sync
- [ ] Sales/Reports filters still work (today/week/month)
- [ ] Low stock thresholds sync correctly from backend to mobile and back
- [ ] Sign-out/login flow still transitions correctly

## Rollout Steps

1. Restart backend with latest sync changes
2. Full restart mobile app (current local DB migration path includes versions up to `9`)
3. Test on unstable network (toggle WiFi/mobile/offline repeatedly)
4. Monitor backend logs for `/sync/push` and `/sync/pull` errors
5. Validate no repeated duplicate rows after reconnect

## Nice-to-Have Next

- Full automated end-to-end chaos/network tests (device-level)
- Periodic release-candidate checklist runs with signoff evidence
- Feature-flag/remote-config gate for Intelligence + Risk rollout (optional ops control)
