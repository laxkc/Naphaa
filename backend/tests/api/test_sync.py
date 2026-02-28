from sqlalchemy import select

from app.models.ledger_entry import LedgerEntry


def test_sync_push_pull_basic_flow(client, auth_headers, store_id):
    push = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {"entity": "customer", "operation": "UPSERT", "payload": {"id": "c1", "name": "C1"}},
                {"entity": "product", "operation": "UPSERT", "payload": {"id": "p1", "name": "P1"}},
            ]
        },
        headers=auth_headers,
    )
    assert push.status_code == 200
    body = push.json()
    assert "acked_op_ids" in body
    assert "failed_events" in body
    assert body["failed_events"] == []

    pull = client.get("/api/v1/sync/pull", params={"limit": 200}, headers=auth_headers)
    assert pull.status_code == 200
    assert len(pull.json()["events"]) == 2


def test_sync_push_duplicate_event_is_idempotent(client, auth_headers, store_id):
    payload = {
        "events": [
            {
                "entity": "product",
                "operation": "UPSERT",
                "payload": {"id": "prod-1", "name": "Prod 1", "sell_price": 100},
            }
        ]
    }

    first = client.post("/api/v1/sync/push", json=payload, headers=auth_headers)
    second = client.post("/api/v1/sync/push", json=payload, headers=auth_headers)
    assert first.status_code == 200
    assert second.status_code == 200

    pull = client.get("/api/v1/sync/pull", params={"limit": 200}, headers=auth_headers)
    assert pull.status_code == 200
    assert len(pull.json()["events"]) == 1


def test_sync_push_legacy_fingerprint_idempotency_without_device_or_op_id(client, auth_headers, store_id):
    payload = {
        "events": [
            {
                "entity": "expense",
                "operation": "UPSERT",
                "payload": {"id": "exp-legacy-1", "category": "OTHER", "amount": 50},
            }
        ]
    }
    first = client.post("/api/v1/sync/push", json=payload, headers=auth_headers)
    second = client.post("/api/v1/sync/push", json=payload, headers=auth_headers)
    assert first.status_code == 200
    assert second.status_code == 200

    pull = client.get("/api/v1/sync/pull", headers=auth_headers)
    events = [e for e in pull.json()["events"] if e["payload"].get("id") == "exp-legacy-1"]
    assert len(events) == 1


def test_sync_large_batch_over_100_events(client, auth_headers, store_id):
    events = [
        {"entity": "product", "operation": "UPSERT", "payload": {"id": f"prod-{i}", "name": f"P{i}"}}
        for i in range(120)
    ]

    push = client.post("/api/v1/sync/push", json={"events": events}, headers=auth_headers)
    assert push.status_code == 200
    assert "acked_op_ids" in push.json()

    pull = client.get("/api/v1/sync/pull", params={"limit": 200}, headers=auth_headers)
    assert pull.status_code == 200
    assert len(pull.json()["events"]) == 120


def test_sync_status_returns_server_metadata(client, auth_headers, store_id):
    push = client.post(
        "/api/v1/sync/push",
        json={"events": [{"entity": "product", "operation": "UPSERT", "payload": {"id": "p1", "name": "P1"}}]},
        headers=auth_headers,
    )
    assert push.status_code == 200
    assert push.json()["failed_events"] == []

    status_resp = client.get("/api/v1/sync/status", headers=auth_headers)
    assert status_resp.status_code == 200
    body = status_resp.json()
    assert body["server_time"]
    assert body["last_event_id"]
    assert body["recommended_pull_since"] is None


def test_sync_pull_since_fallback_compatibility(client, auth_headers, store_id):
    first = client.post(
        "/api/v1/sync/push",
        json={"events": [{"entity": "product", "operation": "UPSERT", "payload": {"id": "p-since-1", "name": "P1"}}]},
        headers=auth_headers,
    )
    assert first.status_code == 200
    first_pull = client.get("/api/v1/sync/pull", headers=auth_headers)
    _ = next(e for e in first_pull.json()["events"] if e["payload"].get("id") == "p-since-1")

    second = client.post(
        "/api/v1/sync/push",
        json={"events": [{"entity": "product", "operation": "UPSERT", "payload": {"id": "p-since-2", "name": "P2"}}]},
        headers=auth_headers,
    )
    assert second.status_code == 200

    since_value = "2000-01-01T00:00:00Z"
    pull = client.get("/api/v1/sync/pull", params={"since": since_value}, headers=auth_headers)
    assert pull.status_code == 200
    ids = {e["payload"].get("id") for e in pull.json()["events"]}
    assert "p-since-1" in ids
    assert "p-since-2" in ids


def test_sync_push_returns_acked_op_ids(client, auth_headers, store_id):
    payload = {
        "events": [
            {
                "op_id": "op-1",
                "device_id": "dev-1",
                "entity": "product",
                "operation": "UPSERT",
                "payload": {"id": "p-ack-1", "name": "Rice"},
            },
            {
                "op_id": "op-2",
                "device_id": "dev-1",
                "entity": "customer",
                "operation": "UPSERT",
                "payload": {"id": "c-ack-1", "name": "Ram"},
            },
        ]
    }
    resp = client.post("/api/v1/sync/push", json=payload, headers=auth_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert sorted(body["acked_op_ids"]) == ["op-1", "op-2"]
    assert body["failed_events"] == []


def test_sync_push_rejects_non_z_timestamps(client, auth_headers, store_id):
    resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "bad-ts-1",
                    "device_id": "dev-ts-1",
                    "entity": "expense",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "exp-ts-1",
                        "category": "OTHER",
                        "amount": 50,
                        "created_at": "2026-02-27T12:00:00+00:00",
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert resp.status_code == 422
    assert "UTC Z format" in resp.text


def test_sync_push_rejects_financial_business_date_mutation(client, auth_headers, store_id):
    first = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "exp-op-1",
                    "device_id": "dev-exp-1",
                    "entity": "expense",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "exp-immutable-1",
                        "category": "OTHER",
                        "amount": 50,
                        "expense_date_ad": "2026-02-27",
                        "created_at": "2026-02-27T12:00:00Z",
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert first.status_code == 200
    assert first.json()["failed_events"] == []

    second = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "exp-op-2",
                    "device_id": "dev-exp-1",
                    "entity": "expense",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "exp-immutable-1",
                        "category": "OTHER",
                        "amount": 75,
                        "expense_date_ad": "2026-02-28",
                        "created_at": "2026-02-27T12:00:00Z",
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert second.status_code == 200
    body = second.json()
    assert body["acked_op_ids"] == []
    assert len(body["failed_events"]) == 1
    assert body["failed_events"][0]["code"] == "IMMUTABLE_BUSINESS_DATE"


def test_sync_push_invalid_event_is_not_acked_and_returns_failure(client, auth_headers, store_id):
    resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "bad-op-1",
                    "device_id": "dev-bad-1",
                    "entity": "unknown_entity",
                    "operation": "UPSERT",
                    "payload": {"id": "x1"},
                }
            ]
        },
        headers=auth_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["acked_op_ids"] == []
    assert len(body["failed_events"]) == 1
    failure = body["failed_events"][0]
    assert failure["op_id"] == "bad-op-1"
    assert failure["code"] == "UNSUPPORTED_ENTITY"


def test_sync_push_duplicate_event_is_acked_idempotently(client, auth_headers, store_id):
    event = {
        "op_id": "dup-ack-1",
        "device_id": "dev-dup-ack-1",
        "entity": "product",
        "operation": "UPSERT",
        "payload": {"id": "dup-ack-prod-1", "name": "Dup Ack Product"},
    }
    first = client.post("/api/v1/sync/push", json={"events": [event]}, headers=auth_headers)
    second = client.post("/api/v1/sync/push", json={"events": [event]}, headers=auth_headers)
    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["acked_op_ids"] == ["dup-ack-1"]
    assert second.json()["acked_op_ids"] == ["dup-ack-1"]
    assert first.json()["failed_events"] == []
    assert second.json()["failed_events"] == []


def test_sync_push_device_op_id_idempotency_overrides_payload_changes(client, auth_headers, store_id):
    first = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "op-idem-1",
                    "device_id": "dev-idem-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {"id": "prod-idem-1", "name": "Original"},
                }
            ]
        },
        headers=auth_headers,
    )
    second = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "op-idem-1",
                    "device_id": "dev-idem-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {"id": "prod-idem-1", "name": "Changed"},
                }
            ]
        },
        headers=auth_headers,
    )
    assert first.status_code == 200
    assert second.status_code == 200

    pull = client.get("/api/v1/sync/pull", headers=auth_headers)
    assert pull.status_code == 200
    events = pull.json()["events"]
    matching = [e for e in events if e["payload"].get("id") == "prod-idem-1"]
    assert len(matching) == 1


def test_sync_pull_cursor_limit_paginates_without_duplicates(client, auth_headers, store_id):
    events = [
        {
            "op_id": f"op-page-{i}",
            "device_id": "dev-page-1",
            "entity": "product",
            "operation": "UPSERT",
            "payload": {"id": f"prod-page-{i}", "name": f"P{i}"},
        }
        for i in range(5)
    ]
    push = client.post("/api/v1/sync/push", json={"events": events}, headers=auth_headers)
    assert push.status_code == 200

    page1 = client.get("/api/v1/sync/pull", params={"limit": 2}, headers=auth_headers)
    assert page1.status_code == 200
    body1 = page1.json()
    assert len(body1["events"]) == 2
    assert body1["next_cursor"]

    page2 = client.get(
        "/api/v1/sync/pull",
        params={"limit": 2, "cursor": body1["next_cursor"]},
        headers=auth_headers,
    )
    assert page2.status_code == 200
    body2 = page2.json()
    assert len(body2["events"]) == 2
    assert body2["next_cursor"]

    page3 = client.get(
        "/api/v1/sync/pull",
        params={"limit": 2, "cursor": body2["next_cursor"]},
        headers=auth_headers,
    )
    assert page3.status_code == 200
    body3 = page3.json()
    assert len(body3["events"]) == 1

    ids1 = [e["id"] for e in body1["events"]]
    ids2 = [e["id"] for e in body2["events"]]
    ids3 = [e["id"] for e in body3["events"]]
    all_ids = ids1 + ids2 + ids3
    assert len(all_ids) == 5
    assert len(set(all_ids)) == 5


def test_sync_push_projects_product_and_delete_into_backend_tables(client, auth_headers, store_id):
    push_upsert = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "prod-upsert-1",
                    "device_id": "dev-proj-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "prod-proj-1",
                        "name": "Soap",
                        "sell_price": 25,
                        "stock_qty": 7,
                        "low_stock_threshold": 2,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert push_upsert.status_code == 200

    get_product = client.get("/api/v1/products/prod-proj-1", headers=auth_headers)
    assert get_product.status_code == 200
    body = get_product.json()
    assert body["name"] == "Soap"

    push_delete = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "prod-del-1",
                    "device_id": "dev-proj-1",
                    "entity": "product",
                    "operation": "DELETE",
                    "payload": {"id": "prod-proj-1"},
                }
            ]
        },
        headers=auth_headers,
    )
    assert push_delete.status_code == 200
    get_deleted = client.get("/api/v1/products/prod-proj-1", headers=auth_headers)
    assert get_deleted.status_code == 404


def test_sync_push_projects_product_adjust_stock(client, auth_headers, store_id):
    seed_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "prod-seed-adjust-1",
                    "device_id": "dev-prod-adjust-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "prod-adjust-1",
                        "name": "Oil",
                        "sell_price": 100,
                        "stock_qty": 10,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert seed_resp.status_code == 200

    adjust_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "prod-adjust-op-1",
                    "device_id": "dev-prod-adjust-1",
                    "entity": "product",
                    "operation": "ADJUST_STOCK",
                    "payload": {
                        "id": "prod-adjust-1",
                        "delta_qty": -3,
                        "reason": "DAMAGE",
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert adjust_resp.status_code == 200
    product_get = client.get("/api/v1/products/prod-adjust-1", headers=auth_headers)
    assert product_get.status_code == 200
    assert float(product_get.json()["stock_qty"]) == 7.0


def test_sync_push_projects_customer_and_payment_balance_change(client, auth_headers, store_id):
    customer_push = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "cust-upsert-1",
                    "device_id": "dev-cust-1",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "cust-proj-1",
                        "name": "Hari",
                        "phone": "9800001111",
                        "balance": 100,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert customer_push.status_code == 200

    payment_push = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "cust-pay-1",
                    "device_id": "dev-cust-1",
                    "entity": "customer_payment",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "cp-proj-1",
                        "customer_id": "cust-proj-1",
                        "method": "CASH",
                        "amount": 30,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert payment_push.status_code == 200

    customer_get = client.get("/api/v1/customers/cust-proj-1", headers=auth_headers)
    assert customer_get.status_code == 200
    # FastAPI JSON encodes Decimal as string in many paths; compare numerically.
    assert float(customer_get.json()["balance"]) == 70.0


def test_sync_push_projects_expense_upsert_and_delete(client, auth_headers, store_id):
    upsert = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "exp-upsert-1",
                    "device_id": "dev-exp-1",
                    "entity": "expense",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "exp-proj-1",
                        "category": "OTHER",
                        "amount": 250,
                        "note": "Offline expense",
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert upsert.status_code == 200
    get_expense = client.get("/api/v1/expenses/exp-proj-1", headers=auth_headers)
    assert get_expense.status_code == 200

    delete_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "exp-del-1",
                    "device_id": "dev-exp-1",
                    "entity": "expense",
                    "operation": "DELETE",
                    "payload": {"id": "exp-proj-1"},
                }
            ]
        },
        headers=auth_headers,
    )
    assert delete_resp.status_code == 200
    get_deleted = client.get("/api/v1/expenses/exp-proj-1", headers=auth_headers)
    assert get_deleted.status_code == 404


def test_sync_push_projects_sale_and_updates_stock_and_credit(client, auth_headers, store_id):
    seed_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "sale-seed-prod-1",
                    "device_id": "dev-sale-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "prod-sale-1",
                        "name": "Rice",
                        "sell_price": 10,
                        "stock_qty": 10,
                    },
                },
                {
                    "op_id": "sale-seed-cust-1",
                    "device_id": "dev-sale-1",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "cust-sale-1",
                        "name": "Sita",
                        "balance": 0,
                    },
                },
            ]
        },
        headers=auth_headers,
    )
    assert seed_resp.status_code == 200

    sale_push = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "sale-upsert-1",
                    "device_id": "dev-sale-1",
                    "entity": "sale",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "sale-proj-1",
                        "sale_type": "CREDIT",
                        "payment_method": "CREDIT",
                        "customer_id": "cust-sale-1",
                        "total_amount": 20,
                        "items": [
                            {"product_id": "prod-sale-1", "qty": 2, "unit_price": 10}
                        ],
                        "payments": [
                            {"id": "sale-pay-1", "method": "CREDIT", "amount": 20}
                        ],
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert sale_push.status_code == 200

    sale_get = client.get("/api/v1/sales/sale-proj-1", headers=auth_headers)
    assert sale_get.status_code == 200
    product_get = client.get("/api/v1/products/prod-sale-1", headers=auth_headers)
    assert product_get.status_code == 200
    customer_get = client.get("/api/v1/customers/cust-sale-1", headers=auth_headers)
    assert customer_get.status_code == 200

    assert float(product_get.json()["stock_qty"]) == 8.0
    assert float(customer_get.json()["balance"]) == 20.0


def test_sync_push_duplicate_sale_replay_does_not_double_apply_stock_or_credit(client, auth_headers, store_id):
    seed_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "dup-sale-seed-prod-1",
                    "device_id": "dev-dup-sale-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "dup-prod-1",
                        "name": "Sugar",
                        "sell_price": 50,
                        "stock_qty": 10,
                    },
                },
                {
                    "op_id": "dup-sale-seed-cust-1",
                    "device_id": "dev-dup-sale-1",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "dup-cust-1",
                        "name": "Mina",
                        "balance": 0,
                    },
                },
            ]
        },
        headers=auth_headers,
    )
    assert seed_resp.status_code == 200

    sale_event = {
        "op_id": "dup-sale-op-1",
        "device_id": "dev-dup-sale-1",
        "entity": "sale",
        "operation": "UPSERT",
        "payload": {
            "id": "dup-sale-1",
            "sale_type": "CREDIT",
            "payment_method": "CREDIT",
            "customer_id": "dup-cust-1",
            "total_amount": 100,
            "items": [{"product_id": "dup-prod-1", "qty": 2, "unit_price": 50}],
            "payments": [{"id": "dup-sale-pay-1", "method": "CREDIT", "amount": 100}],
        },
    }
    first = client.post("/api/v1/sync/push", json={"events": [sale_event]}, headers=auth_headers)
    second = client.post("/api/v1/sync/push", json={"events": [sale_event]}, headers=auth_headers)
    assert first.status_code == 200
    assert second.status_code == 200

    product_get = client.get("/api/v1/products/dup-prod-1", headers=auth_headers)
    customer_get = client.get("/api/v1/customers/dup-cust-1", headers=auth_headers)
    sale_get = client.get("/api/v1/sales/dup-sale-1", headers=auth_headers)
    assert sale_get.status_code == 200
    assert float(product_get.json()["stock_qty"]) == 8.0
    assert float(customer_get.json()["balance"]) == 100.0


def test_sync_push_financial_events_create_ledger_entries(client, auth_headers, store_id, db_session):
    seed_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "ledger-seed-prod",
                    "device_id": "dev-ledger-sync",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {"id": "ledger-sync-prod", "name": "Rice", "sell_price": 20, "stock_qty": 10},
                },
                {
                    "op_id": "ledger-seed-cust",
                    "device_id": "dev-ledger-sync",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {"id": "ledger-sync-cust", "name": "Hari", "balance": 0},
                },
            ]
        },
        headers=auth_headers,
    )
    assert seed_resp.status_code == 200

    push = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "ledger-sync-sale",
                    "device_id": "dev-ledger-sync",
                    "entity": "sale",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "ledger-sync-sale-1",
                        "sale_type": "CREDIT",
                        "payment_method": "CREDIT",
                        "customer_id": "ledger-sync-cust",
                        "total_amount": 40,
                        "items": [{"product_id": "ledger-sync-prod", "qty": 2, "unit_price": 20}],
                        "payments": [{"id": "ledger-sync-pay-1", "method": "CREDIT", "amount": 40}],
                    },
                },
                {
                    "op_id": "ledger-sync-custpay",
                    "device_id": "dev-ledger-sync",
                    "entity": "customer_payment",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "ledger-sync-custpay-1",
                        "customer_id": "ledger-sync-cust",
                        "method": "CASH",
                        "amount": 10,
                    },
                },
                {
                    "op_id": "ledger-sync-exp",
                    "device_id": "dev-ledger-sync",
                    "entity": "expense",
                    "operation": "UPSERT",
                    "payload": {"id": "ledger-sync-exp-1", "category": "OTHER", "amount": 5},
                },
            ]
        },
        headers=auth_headers,
    )
    assert push.status_code == 200
    assert push.json()["failed_events"] == []

    rows = db_session.scalars(select(LedgerEntry).where(LedgerEntry.store_id == store_id)).all()
    by_key = {(r.entity_type, r.entity_id): r for r in rows}
    assert ("sale", "ledger-sync-sale-1") in by_key
    assert ("customer_payment", "ledger-sync-custpay-1") in by_key
    assert ("expense", "ledger-sync-exp-1") in by_key


def test_sync_push_invalid_sale_event_does_not_partially_apply(client, auth_headers, store_id):
    seed_resp = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "strict-sale-seed-prod-1",
                    "device_id": "dev-strict-sale-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "strict-prod-1",
                        "name": "Flour",
                        "sell_price": 100,
                        "stock_qty": 5,
                    },
                },
                {
                    "op_id": "strict-sale-seed-cust-1",
                    "device_id": "dev-strict-sale-1",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "strict-cust-1",
                        "name": "Bina",
                        "balance": 0,
                    },
                },
            ]
        },
        headers=auth_headers,
    )
    assert seed_resp.status_code == 200

    bad_sale = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "strict-sale-bad-1",
                    "device_id": "dev-strict-sale-1",
                    "entity": "sale",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "strict-sale-1",
                        "sale_type": "CREDIT",
                        "payment_method": "CREDIT",
                        "customer_id": "strict-cust-1",
                        "total_amount": 100,
                        "items": [
                            {"product_id": "strict-prod-1", "qty": 2, "unit_price": 50},
                            {"product_id": "missing-prod", "qty": 1, "unit_price": 10},
                        ],
                        "payments": [{"id": "strict-pay-1", "method": "CREDIT", "amount": 100}],
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert bad_sale.status_code == 200
    body = bad_sale.json()
    assert body["acked_op_ids"] == []
    assert len(body["failed_events"]) == 1
    assert body["failed_events"][0]["code"] == "PRODUCT_NOT_FOUND"

    sale_get = client.get("/api/v1/sales/strict-sale-1", headers=auth_headers)
    assert sale_get.status_code == 404
    product_get = client.get("/api/v1/products/strict-prod-1", headers=auth_headers)
    customer_get = client.get("/api/v1/customers/strict-cust-1", headers=auth_headers)
    assert float(product_get.json()["stock_qty"]) == 5.0
    assert float(customer_get.json()["balance"]) == 0.0


def test_sync_push_rejects_stale_product_upsert_conflict(client, auth_headers, store_id):
    newer = "2026-02-24T12:00:00Z"
    older = "2026-02-24T11:00:00Z"
    seed = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "prod-conflict-seed-1",
                    "device_id": "dev-conflict-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "prod-conflict-1",
                        "name": "Current Name",
                        "sell_price": 10,
                        "stock_qty": 5,
                        "updated_at": newer,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert seed.status_code == 200

    stale = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "prod-conflict-stale-1",
                    "device_id": "dev-conflict-1",
                    "entity": "product",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "prod-conflict-1",
                        "name": "Stale Name",
                        "sell_price": 999,
                        "updated_at": older,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert stale.status_code == 200
    body = stale.json()
    assert body["acked_op_ids"] == []
    assert body["failed_events"][0]["code"] == "CONFLICT_STALE_EVENT"

    product_get = client.get("/api/v1/products/prod-conflict-1", headers=auth_headers)
    assert product_get.status_code == 200
    assert product_get.json()["name"] == "Current Name"
    assert float(product_get.json()["sell_price"]) == 10.0


def test_sync_push_rejects_stale_customer_upsert_conflict(client, auth_headers, store_id):
    newer = "2026-02-24T12:00:00Z"
    older = "2026-02-24T11:00:00Z"
    seed = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "cust-conflict-seed-1",
                    "device_id": "dev-conflict-2",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "cust-conflict-1",
                        "name": "Current Customer",
                        "balance": 15,
                        "updated_at": newer,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert seed.status_code == 200

    stale = client.post(
        "/api/v1/sync/push",
        json={
            "events": [
                {
                    "op_id": "cust-conflict-stale-1",
                    "device_id": "dev-conflict-2",
                    "entity": "customer",
                    "operation": "UPSERT",
                    "payload": {
                        "id": "cust-conflict-1",
                        "name": "Stale Customer",
                        "balance": 999,
                        "updated_at": older,
                    },
                }
            ]
        },
        headers=auth_headers,
    )
    assert stale.status_code == 200
    body = stale.json()
    assert body["acked_op_ids"] == []
    assert body["failed_events"][0]["code"] == "CONFLICT_STALE_EVENT"

    customer_get = client.get("/api/v1/customers/cust-conflict-1", headers=auth_headers)
    assert customer_get.status_code == 200
    assert customer_get.json()["name"] == "Current Customer"
    assert float(customer_get.json()["balance"]) == 15.0
