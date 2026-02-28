from __future__ import annotations

import socket
import sys

from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

from app.core.config import settings


def main() -> int:
    host = settings.db_host
    port = settings.db_port

    print(f"DB host: {host}")
    print(f"DB port: {port}")
    print(f"DB name: {settings.db_name}")
    print(f"DB user: {settings.db_user}")

    try:
        resolved = socket.getaddrinfo(host, port)
        ips = sorted({item[4][0] for item in resolved})
        print(f"DNS resolved: {', '.join(ips)}")
    except OSError as exc:
        print(f"DNS resolution failed: {exc}")
        return 2

    try:
        engine = create_engine(settings.effective_database_url, future=True)
        with engine.connect() as conn:
            value = conn.execute(text("select 1")).scalar()
        engine.dispose()
        print(f"Connection OK: select 1 -> {value}")
        return 0
    except OperationalError as exc:
        print(f"Database connection failed: {exc}")
        return 3


if __name__ == "__main__":
    sys.exit(main())
