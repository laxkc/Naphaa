from collections.abc import Generator
from pathlib import Path
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.api.deps import get_db
from app.core.database import Base
from app.core.rate_limit import _auth_limiter
from app.main import app


@pytest.fixture()
def db_session(tmp_path: Path) -> Generator[Session, None, None]:
    db_path = tmp_path / "test.db"
    engine = create_engine(
        f"sqlite:///{db_path}",
        connect_args={"check_same_thread": False},
        future=True,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


@pytest.fixture()
def client(db_session: Session) -> Generator[TestClient, None, None]:
    def _get_test_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = _get_test_db
    with TestClient(app) as tc:
        yield tc
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_rate_limiters() -> Generator[None, None, None]:
    # Auth limiter is process-global in-memory state; reset between tests.
    _auth_limiter._requests.clear()
    yield
    _auth_limiter._requests.clear()


@pytest.fixture()
def auth_headers(client: TestClient) -> dict[str, str]:
    phone = f"98{str(uuid.uuid4().int % 10**8).zfill(8)}"
    reg = client.post(
        "/api/v1/auth/register",
        json={"phone": phone, "password": "secret123"},
    )
    assert reg.status_code == 200, reg.text
    token = reg.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def second_auth_headers(client: TestClient) -> dict[str, str]:
    phone = f"98{str(uuid.uuid4().int % 10**8).zfill(8)}"
    reg = client.post(
        "/api/v1/auth/register",
        json={"phone": phone, "password": "secret123"},
    )
    assert reg.status_code == 200, reg.text
    token = reg.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def store_id(client: TestClient, auth_headers: dict[str, str]) -> str:
    resp = client.post(
        "/api/v1/stores",
        json={"name": "Store One", "currency": "NPR"},
        headers=auth_headers,
    )
    return resp.json()["id"]


@pytest.fixture()
def second_store_id(client: TestClient, second_auth_headers: dict[str, str]) -> str:
    resp = client.post(
        "/api/v1/stores",
        json={"name": "Store Two", "currency": "NPR"},
        headers=second_auth_headers,
    )
    return resp.json()["id"]
