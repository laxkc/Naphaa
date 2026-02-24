def test_auth_register_login_refresh(client):
    register = client.post(
        "/api/v1/auth/register",
        json={"phone": "9811111111", "password": "pass1234"},
    )
    assert register.status_code == 200
    data = register.json()
    assert "access_token" in data
    assert "refresh_token" in data

    login = client.post(
        "/api/v1/auth/login",
        json={"phone": "9811111111", "password": "pass1234"},
    )
    assert login.status_code == 200

    refresh = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": login.json()["refresh_token"]},
    )
    assert refresh.status_code == 200
    rotated = refresh.json()
    assert rotated["refresh_token"] != login.json()["refresh_token"]

    old_refresh_reuse = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": login.json()["refresh_token"]},
    )
    assert old_refresh_reuse.status_code == 401
    assert old_refresh_reuse.json()["detail"]["code"] == "TOKEN_REVOKED"

    new_refresh = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": rotated["refresh_token"]},
    )
    assert new_refresh.status_code == 200


def test_store_create_me_update(client, auth_headers):
    create = client.post(
        "/api/v1/stores",
        json={"name": "My Shop", "currency": "NPR"},
        headers=auth_headers,
    )
    assert create.status_code == 200
    store_id = create.json()["id"]

    me = client.get("/api/v1/stores/me", headers=auth_headers)
    assert me.status_code == 200
    assert me.json()["id"] == store_id

    update = client.patch(
        f"/api/v1/stores/{store_id}",
        json={"name": "My Shop Updated"},
        headers=auth_headers,
    )
    assert update.status_code == 200
    assert update.json()["name"] == "My Shop Updated"


def test_store_locale_defaults_from_accept_language(client, auth_headers):
    create = client.post(
        "/api/v1/stores",
        json={"name": "Locale Shop", "currency": "NPR"},
        headers={**auth_headers, "Accept-Language": "en-US,en;q=0.9"},
    )
    assert create.status_code == 200
    assert create.json()["locale_default"] == "en"


def test_store_requires_auth(client):
    resp = client.get("/api/v1/stores/me")
    assert resp.status_code == 401


def test_auth_register_with_business_name_creates_store_and_me(client):
    register = client.post(
        "/api/v1/auth/register",
        json={
            "phone": "9822222222",
            "password": "pass1234",
            "business_name": "Sunrise Mart",
            "locale_default": "en",
            "currency": "NPR",
        },
    )
    assert register.status_code == 200

    token = register.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    me = client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 200
    body = me.json()
    assert body["phone"] == "9822222222"
    assert body["role"] == "owner"
    assert body["store_name"] == "Sunrise Mart"
    assert body["locale_default"] == "en"


def test_auth_logout_revokes_refresh_token(client):
    register = client.post(
        "/api/v1/auth/register",
        json={"phone": "9833333333", "password": "pass1234"},
    )
    assert register.status_code == 200
    refresh_token = register.json()["refresh_token"]

    logout = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout.status_code == 200

    refresh = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh.status_code == 401
    assert refresh.json()["detail"]["code"] == "TOKEN_REVOKED"


def test_auth_change_password_and_login(client):
    register = client.post(
        "/api/v1/auth/register",
        json={"phone": "9844444444", "password": "pass1234"},
    )
    assert register.status_code == 200
    token = register.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    change = client.post(
        "/api/v1/auth/change-password",
        json={"current_password": "pass1234", "new_password": "newpass5678"},
        headers=headers,
    )
    assert change.status_code == 200

    old_login = client.post(
        "/api/v1/auth/login",
        json={"phone": "9844444444", "password": "pass1234"},
    )
    assert old_login.status_code == 401

    new_login = client.post(
        "/api/v1/auth/login",
        json={"phone": "9844444444", "password": "newpass5678"},
    )
    assert new_login.status_code == 200
