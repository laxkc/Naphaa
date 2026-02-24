from sqlalchemy import select

from app.models.sync_event import SyncEvent


def _create_product(client, auth_headers):
    resp = client.post(
        "/api/v1/products",
        json={"name": "Soap", "sell_price": 60, "stock_qty": 25},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    return resp.json()["id"]


def _sync_events_for_entity_id(db_session, *, entity: str, entity_id: str):
    rows = db_session.scalars(
        select(SyncEvent).where(SyncEvent.entity == entity).order_by(SyncEvent.created_at, SyncEvent.id)
    ).all()
    return [row for row in rows if row.payload.get("id") == entity_id]


def _latest_sync_event_for_entity_id(db_session, *, entity: str, entity_id: str):
    events = _sync_events_for_entity_id(db_session, entity=entity, entity_id=entity_id)
    assert events, f"No sync events found for {entity}:{entity_id}"
    return events[-1]


def test_product_api_emits_sync_events_with_schema_version(client, auth_headers, store_id, db_session):
    create = client.post(
        "/api/v1/products",
        json={"name": "Emit Product", "sell_price": 120, "stock_qty": 10},
        headers=auth_headers,
    )
    assert create.status_code == 200
    product_id = create.json()["id"]

    patch = client.patch(
        f"/api/v1/products/{product_id}",
        json={"stock_qty": 11},
        headers=auth_headers,
    )
    assert patch.status_code == 200

    adjust = client.post(
        f"/api/v1/products/{product_id}/adjust-stock",
        json={"delta_qty": -2, "reason": "DAMAGE"},
        headers=auth_headers,
    )
    assert adjust.status_code == 200

    delete = client.delete(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert delete.status_code == 204

    events = _sync_events_for_entity_id(db_session, entity="product", entity_id=product_id)
    operations = [e.operation for e in events]
    assert "UPSERT" in operations
    assert "ADJUST_STOCK" in operations
    assert "DELETE" in operations
    assert all(e.payload.get("schema_version") == 1 for e in events)


def test_product_api_create_and_delete_emit_expected_operations(client, auth_headers, store_id, db_session):
    create = client.post(
        "/api/v1/products",
        json={"name": "Emit Product Ops", "sell_price": 90, "stock_qty": 5},
        headers=auth_headers,
    )
    assert create.status_code == 200
    product_id = create.json()["id"]

    created_event = _latest_sync_event_for_entity_id(db_session, entity="product", entity_id=product_id)
    assert created_event.operation == "UPSERT"
    assert created_event.payload.get("schema_version") == 1

    delete = client.delete(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert delete.status_code == 204
    product_events = _sync_events_for_entity_id(db_session, entity="product", entity_id=product_id)
    delete_events = [e for e in product_events if e.operation == "DELETE"]
    assert delete_events
    assert all(e.payload.get("schema_version") == 1 for e in delete_events)


def test_customer_api_emits_sync_events_with_schema_version(client, auth_headers, store_id, db_session):
    create = client.post("/api/v1/customers", json={"name": "Emit Customer"}, headers=auth_headers)
    assert create.status_code == 200
    customer_id = create.json()["id"]

    patch = client.patch(
        f"/api/v1/customers/{customer_id}",
        json={"phone": "9801234567"},
        headers=auth_headers,
    )
    assert patch.status_code == 200

    delete = client.delete(f"/api/v1/customers/{customer_id}", headers=auth_headers)
    assert delete.status_code == 204

    events = _sync_events_for_entity_id(db_session, entity="customer", entity_id=customer_id)
    operations = [e.operation for e in events]
    assert "UPSERT" in operations
    assert "DELETE" in operations
    assert all(e.payload.get("schema_version") == 1 for e in events)


def test_customer_api_create_and_delete_emit_expected_operations(client, auth_headers, store_id, db_session):
    create = client.post("/api/v1/customers", json={"name": "Emit Customer Ops"}, headers=auth_headers)
    assert create.status_code == 200
    customer_id = create.json()["id"]

    created_event = _latest_sync_event_for_entity_id(db_session, entity="customer", entity_id=customer_id)
    assert created_event.operation == "UPSERT"
    assert created_event.payload.get("schema_version") == 1

    delete = client.delete(f"/api/v1/customers/{customer_id}", headers=auth_headers)
    assert delete.status_code == 204
    customer_events = _sync_events_for_entity_id(db_session, entity="customer", entity_id=customer_id)
    delete_events = [e for e in customer_events if e.operation == "DELETE"]
    assert delete_events
    assert all(e.payload.get("schema_version") == 1 for e in delete_events)


def test_customer_payment_and_sale_apis_emit_sync_events_with_schema_version(
    client,
    auth_headers,
    store_id,
    db_session,
):
    product_id = _create_product(client, auth_headers)
    customer = client.post("/api/v1/customers", json={"name": "Emit Pay"}, headers=auth_headers)
    assert customer.status_code == 200
    customer_id = customer.json()["id"]

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CREDIT",
            "customer_id": customer_id,
            "items": [{"product_id": product_id, "qty": 2, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200
    sale_id = sale.json()["id"]

    payment = client.post(
        f"/api/v1/customers/{customer_id}/payments",
        json={"amount": 50, "method": "CASH"},
        headers=auth_headers,
    )
    assert payment.status_code == 200
    payment_id = payment.json()["id"]

    sale_events = _sync_events_for_entity_id(db_session, entity="sale", entity_id=sale_id)
    payment_events = _sync_events_for_entity_id(db_session, entity="customer_payment", entity_id=payment_id)
    customer_events = _sync_events_for_entity_id(db_session, entity="customer", entity_id=customer_id)

    assert any(e.operation == "UPSERT" for e in sale_events)
    assert any(e.operation == "UPSERT" for e in payment_events)
    assert any(e.operation == "UPSERT" for e in customer_events)
    assert all(e.payload.get("schema_version") == 1 for e in sale_events + payment_events + customer_events)


def test_expense_api_emits_sync_events_with_schema_version(client, auth_headers, store_id, db_session):
    create = client.post(
        "/api/v1/expenses",
        json={"category": "transport", "amount": 20, "note": "delivery"},
        headers=auth_headers,
    )
    assert create.status_code == 200
    expense_id = create.json()["id"]

    delete = client.delete(f"/api/v1/expenses/{expense_id}", headers=auth_headers)
    assert delete.status_code == 204

    events = _sync_events_for_entity_id(db_session, entity="expense", entity_id=expense_id)
    operations = [e.operation for e in events]
    assert "UPSERT" in operations
    assert "DELETE" in operations
    assert all(e.payload.get("schema_version") == 1 for e in events)


def test_product_crud(client, auth_headers, store_id):
    create = client.post(
        "/api/v1/products",
        json={"name": "Rice", "sell_price": 120, "stock_qty": 50},
        headers=auth_headers,
    )
    assert create.status_code == 200
    product_id = create.json()["id"]

    list_resp = client.get("/api/v1/products", headers=auth_headers)
    assert list_resp.status_code == 200
    list_body = list_resp.json()
    assert list_body["total"] == 1
    assert len(list_body["items"]) == 1

    get_resp = client.get(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert get_resp.status_code == 200

    patch_resp = client.patch(
        f"/api/v1/products/{product_id}",
        json={"stock_qty": 42},
        headers=auth_headers,
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["stock_qty"] == "42.00"

    delete_resp = client.delete(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert delete_resp.status_code == 204
    deleted_get = client.get(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert deleted_get.status_code == 404


def test_create_sale_updates_stock_and_credit(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Hari"},
        headers=auth_headers,
    )
    assert customer.status_code == 200

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CREDIT",
            "customer_id": customer.json()["id"],
            "items": [{"product_id": product_id, "qty": 3, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200
    assert sale.json()["total_amount"] == "180.00"

    product = client.get(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert product.status_code == 200
    assert product.json()["stock_qty"] == "22.00"

    customer_after = client.get(
        f"/api/v1/customers/{customer.json()['id']}",
        headers=auth_headers,
    )
    assert customer_after.status_code == 200
    assert customer_after.json()["balance"] == "180.00"


def test_expense_and_report_summary(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CASH",
            "items": [{"product_id": product_id, "qty": 2, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200

    expense = client.post(
        "/api/v1/expenses",
        json={"category": "transport", "amount": 20, "note": "delivery"},
        headers=auth_headers,
    )
    assert expense.status_code == 200
    assert expense.json()["category"] == "TRANSPORT"

    summary = client.get("/api/v1/reports/summary", headers=auth_headers)
    assert summary.status_code == 200
    body = summary.json()
    assert body["total_sales"] == "120.00"
    assert body["total_expenses"] == "20.00"
    assert body["estimated_profit"] == "100.00"


def test_validation_error_for_empty_sale_items(client, auth_headers, store_id):
    resp = client.post(
        "/api/v1/sales",
        json={"sale_type": "CASH", "items": []},
        headers=auth_headers,
    )
    assert resp.status_code == 400


def test_store_isolation_on_products(
    client,
    auth_headers,
    second_auth_headers,
    store_id,
    second_store_id,
):
    product_id = _create_product(client, auth_headers)

    other_user_get = client.get(f"/api/v1/products/{product_id}", headers=second_auth_headers)
    assert other_user_get.status_code == 404


def test_sales_idempotency_key_prevents_duplicates(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    headers = {**auth_headers, "Idempotency-Key": "sale-unique-001"}
    payload = {
        "sale_type": "CASH",
        "items": [{"product_id": product_id, "qty": 2, "unit_price": 10}],
    }

    first = client.post("/api/v1/sales", json=payload, headers=headers)
    assert first.status_code == 200

    second = client.post("/api/v1/sales", json=payload, headers=headers)
    assert second.status_code == 200
    assert first.json()["id"] == second.json()["id"]

    sales = client.get("/api/v1/sales", headers=auth_headers).json()
    assert sales["total"] == 1


def test_adjust_stock_endpoint(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    adjust = client.post(
        f"/api/v1/products/{product_id}/adjust-stock",
        json={"delta_qty": -2, "reason": "DAMAGE"},
        headers=auth_headers,
    )
    assert adjust.status_code == 200
    assert adjust.json()["stock_qty"] == "23.00"


def test_customer_payment_reduces_balance_and_records_history(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Sita"},
        headers=auth_headers,
    )
    assert customer.status_code == 200
    customer_id = customer.json()["id"]

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CREDIT",
            "customer_id": customer_id,
            "items": [{"product_id": product_id, "qty": 2, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200

    payment = client.post(
        f"/api/v1/customers/{customer_id}/payments",
        json={"amount": 100, "note": "Cash collected"},
        headers=auth_headers,
    )
    assert payment.status_code == 200
    assert payment.json()["amount"] == "100.00"

    customer_after = client.get(f"/api/v1/customers/{customer_id}", headers=auth_headers)
    assert customer_after.status_code == 200
    assert customer_after.json()["balance"] == "20.00"


def test_low_stock_report(client, auth_headers, store_id):
    create = client.post(
        "/api/v1/products",
        json={
            "name": "Noodles",
            "sell_price": 50,
            "stock_qty": 2,
            "low_stock_threshold": 3,
        },
        headers=auth_headers,
    )
    assert create.status_code == 200
    product_id = create.json()["id"]

    report = client.get("/api/v1/reports/low-stock", headers=auth_headers)
    assert report.status_code == 200
    items = report.json()["items"]
    assert any(item["product_id"] == product_id for item in items)


def test_sale_refund_restocks_and_reduces_credit(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Refund Customer"},
        headers=auth_headers,
    )
    assert customer.status_code == 200
    customer_id = customer.json()["id"]

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CREDIT",
            "customer_id": customer_id,
            "items": [{"product_id": product_id, "qty": 3, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200
    sale_id = sale.json()["id"]
    assert sale.json()["total_amount"] == "180.00"

    refund = client.post(
        f"/api/v1/sales/{sale_id}/refund",
        json={"items": [{"product_id": product_id, "qty": 2}], "reason": "RETURNED"},
        headers=auth_headers,
    )
    assert refund.status_code == 200
    assert refund.json()["amount"] == "120.00"

    sale_after = client.get(f"/api/v1/sales/{sale_id}", headers=auth_headers)
    assert sale_after.status_code == 200
    assert sale_after.json()["total_amount"] == "60.00"

    product_after = client.get(f"/api/v1/products/{product_id}", headers=auth_headers)
    assert product_after.status_code == 200
    assert product_after.json()["stock_qty"] == "24.00"

    customer_after = client.get(f"/api/v1/customers/{customer_id}", headers=auth_headers)
    assert customer_after.status_code == 200
    assert customer_after.json()["balance"] == "60.00"


def test_sale_split_payments_updates_only_credit_balance(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Split Payment"},
        headers=auth_headers,
    )
    assert customer.status_code == 200
    customer_id = customer.json()["id"]

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "MIXED",
            "customer_id": customer_id,
            "items": [{"product_id": product_id, "qty": 2, "unit_price": 60}],
            "payments": [
                {"method": "CASH", "amount": 70},
                {"method": "CREDIT", "amount": 50},
            ],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200

    customer_after = client.get(f"/api/v1/customers/{customer_id}", headers=auth_headers)
    assert customer_after.status_code == 200
    assert customer_after.json()["balance"] == "50.00"


def test_customer_ledger_contains_sales_payments_and_running_balance(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "Ledger Customer"},
        headers=auth_headers,
    )
    customer_id = customer.json()["id"]

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CREDIT",
            "customer_id": customer_id,
            "items": [{"product_id": product_id, "qty": 2, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    assert sale.status_code == 200

    payment = client.post(
        f"/api/v1/customers/{customer_id}/payments",
        json={"amount": 20, "method": "CASH"},
        headers=auth_headers,
    )
    assert payment.status_code == 200

    ledger = client.get(f"/api/v1/customers/{customer_id}/ledger", headers=auth_headers)
    assert ledger.status_code == 200
    items = ledger.json()["items"]
    assert len(items) >= 2
    assert any(i["type"] == "SALE" for i in items)
    assert any(i["type"] == "PAYMENT" for i in items)
    assert items[-1]["running_balance"] == "100.00"


def test_product_stock_history_shows_sale_adjustment_and_refund(client, auth_headers, store_id):
    product_id = _create_product(client, auth_headers)
    customer = client.post(
        "/api/v1/customers",
        json={"name": "History Customer"},
        headers=auth_headers,
    )
    customer_id = customer.json()["id"]

    sale = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CREDIT",
            "customer_id": customer_id,
            "items": [{"product_id": product_id, "qty": 1, "unit_price": 60}],
        },
        headers=auth_headers,
    )
    sale_id = sale.json()["id"]

    adjust = client.post(
        f"/api/v1/products/{product_id}/adjust-stock",
        json={"delta_qty": -1, "reason": "DAMAGE"},
        headers=auth_headers,
    )
    assert adjust.status_code == 200

    refund = client.post(
        f"/api/v1/sales/{sale_id}/refund",
        json={"items": [{"product_id": product_id, "qty": 1}], "reason": "RETURN"},
        headers=auth_headers,
    )
    assert refund.status_code == 200

    history = client.get(f"/api/v1/products/{product_id}/stock-history", headers=auth_headers)
    assert history.status_code == 200
    movement_types = [i["type"] for i in history.json()["items"]]
    assert "SALE_DEDUCTION" in movement_types
    assert "MANUAL_ADJUSTMENT" in movement_types
    assert "REFUND_RESTOCK" in movement_types


def test_devices_register(client, auth_headers):
    resp = client.post(
        "/api/v1/devices/register",
        json={"device_id": "iphone-17-promax-1", "platform": "ios", "app_version": "1.0.0"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["device_id"] == "iphone-17-promax-1"

    list_resp = client.get("/api/v1/devices", headers=auth_headers)
    assert list_resp.status_code == 200
    assert any(d["device_id"] == "iphone-17-promax-1" for d in list_resp.json())


def test_products_search_and_sort(client, auth_headers, store_id):
    p1 = client.post(
        "/api/v1/products",
        json={"name": "Noodles", "sell_price": 30, "stock_qty": 10},
        headers=auth_headers,
    )
    p2 = client.post(
        "/api/v1/products",
        json={"name": "Rice", "sell_price": 120, "stock_qty": 50},
        headers=auth_headers,
    )
    assert p1.status_code == 200
    assert p2.status_code == 200

    search = client.get("/api/v1/products?search=nood", headers=auth_headers)
    assert search.status_code == 200
    assert search.json()["total"] == 1
    assert search.json()["items"][0]["name"] == "Noodles"

    sorted_resp = client.get(
        "/api/v1/products?sort=sell_price&order=asc",
        headers=auth_headers,
    )
    assert sorted_resp.status_code == 200
    prices = [float(i["sell_price"]) for i in sorted_resp.json()["items"]]
    assert prices == sorted(prices)


def test_customers_search_and_sort(client, auth_headers, store_id):
    c1 = client.post("/api/v1/customers", json={"name": "Ram"}, headers=auth_headers)
    c2 = client.post("/api/v1/customers", json={"name": "Sita"}, headers=auth_headers)
    assert c1.status_code == 200
    assert c2.status_code == 200

    search = client.get("/api/v1/customers?search=ram", headers=auth_headers)
    assert search.status_code == 200
    assert search.json()["total"] == 1
    assert search.json()["items"][0]["name"] == "Ram"

    sorted_resp = client.get(
        "/api/v1/customers?sort=name&order=asc",
        headers=auth_headers,
    )
    assert sorted_resp.status_code == 200
    names = [i["name"] for i in sorted_resp.json()["items"]]
    assert names == sorted(names)


def test_reports_cashbook_top_products_and_export_full(client, auth_headers, store_id):
    p1 = client.post(
        "/api/v1/products",
        json={"name": "Rice", "sell_price": 100, "stock_qty": 20},
        headers=auth_headers,
    )
    p2 = client.post(
        "/api/v1/products",
        json={"name": "Soap", "sell_price": 40, "stock_qty": 20},
        headers=auth_headers,
    )
    assert p1.status_code == 200
    assert p2.status_code == 200
    p1_id = p1.json()["id"]
    p2_id = p2.json()["id"]

    sale1 = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CASH",
            "items": [{"product_id": p1_id, "qty": 2, "unit_price": 100}],
            "payment_method": "CASH",
        },
        headers=auth_headers,
    )
    assert sale1.status_code == 200

    sale2 = client.post(
        "/api/v1/sales",
        json={
            "sale_type": "CASH",
            "items": [{"product_id": p2_id, "qty": 1, "unit_price": 40}],
            "payment_method": "QR",
        },
        headers=auth_headers,
    )
    assert sale2.status_code == 200

    cashbook = client.get("/api/v1/reports/cashbook", headers=auth_headers)
    assert cashbook.status_code == 200
    cashbook_body = cashbook.json()
    assert cashbook_body["cash_total"] == "200.00"
    assert cashbook_body["qr_total"] == "40.00"

    top_products = client.get("/api/v1/reports/top-products", headers=auth_headers)
    assert top_products.status_code == 200
    tp_items = top_products.json()["items"]
    assert len(tp_items) >= 2
    assert tp_items[0]["name"] == "Rice"

    export_resp = client.get("/api/v1/exports/full", headers=auth_headers)
    assert export_resp.status_code == 200
    export_body = export_resp.json()
    assert export_body["store"]["id"] == store_id
    assert len(export_body["products"]) >= 2
    assert len(export_body["sales"]) >= 2
