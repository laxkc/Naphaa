# Offline-First Test & Rollout Checklist (Phase 8)

Last updated: 2026-02-23

## Automated Checks (Current)

- Mobile static analysis: `flutter analyze`
- Backend import smoke check: `./.venv/bin/python -c "import app.main; print('ok')"`

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
2. Full restart mobile app (DB migrations: versions 6/7 in current refactor path)
3. Test on unstable network (toggle WiFi/mobile/offline repeatedly)
4. Monitor backend logs for `/sync/push` and `/sync/pull` errors
5. Validate no repeated duplicate rows after reconnect

## Nice-to-Have Next

- Backend integration tests for `/sync/push` and `/sync/pull` cursor pagination
- Mobile repository/sync service tests with local SQLite fixture
- Debug sync queue screen for support staff

