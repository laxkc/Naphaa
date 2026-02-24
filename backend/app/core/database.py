from collections.abc import Generator

from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings


class Base(DeclarativeBase):
    pass


engine_kwargs: dict[str, object] = {}
if settings.database_url.startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(settings.database_url, future=True, **engine_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def run_sqlite_compat_migrations() -> None:
    """Apply lightweight schema patches for local sqlite dev DBs."""
    if not settings.database_url.startswith("sqlite"):
        return

    with engine.begin() as conn:
        table_rows = conn.execute(
            text("SELECT name FROM sqlite_master WHERE type='table'")
        ).fetchall()
        tables = {row[0] for row in table_rows}

        _sqlite_add_column_if_missing(
            conn,
            tables,
            "stores",
            "locale_default",
            "ALTER TABLE stores ADD COLUMN locale_default VARCHAR(16) DEFAULT 'ne'",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "sync_events",
            "fingerprint",
            "ALTER TABLE sync_events ADD COLUMN fingerprint VARCHAR(64) DEFAULT ''",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "users",
            "role",
            "ALTER TABLE users ADD COLUMN role VARCHAR(16) DEFAULT 'owner'",
        )

        # Audit and soft-delete compatibility columns.
        for table in ("stores", "products", "customers", "sales", "expenses"):
            _sqlite_add_column_if_missing(
                conn,
                tables,
                table,
                "created_by",
                f"ALTER TABLE {table} ADD COLUMN created_by VARCHAR(36)",
            )
            _sqlite_add_column_if_missing(
                conn,
                tables,
                table,
                "updated_by",
                f"ALTER TABLE {table} ADD COLUMN updated_by VARCHAR(36)",
            )
            _sqlite_add_column_if_missing(
                conn,
                tables,
                table,
                "device_id",
                f"ALTER TABLE {table} ADD COLUMN device_id VARCHAR(128)",
            )
            _sqlite_add_column_if_missing(
                conn,
                tables,
                table,
                "deleted_at",
                f"ALTER TABLE {table} ADD COLUMN deleted_at DATETIME",
            )

        _sqlite_add_column_if_missing(
            conn,
            tables,
            "products",
            "is_deleted",
            "ALTER TABLE products ADD COLUMN is_deleted BOOLEAN DEFAULT 0",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "products",
            "created_at",
            "ALTER TABLE products ADD COLUMN created_at DATETIME",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "customers",
            "created_at",
            "ALTER TABLE customers ADD COLUMN created_at DATETIME",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "customers",
            "is_deleted",
            "ALTER TABLE customers ADD COLUMN is_deleted BOOLEAN DEFAULT 0",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "sales",
            "idempotency_key",
            "ALTER TABLE sales ADD COLUMN idempotency_key VARCHAR(72)",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "sales",
            "payment_method",
            "ALTER TABLE sales ADD COLUMN payment_method VARCHAR(24)",
        )
        if "sales" in tables:
            conn.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS uq_sale_store_idempotency "
                    "ON sales(store_id, idempotency_key) "
                    "WHERE idempotency_key IS NOT NULL"
                )
            )

        if "customer_payments" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE customer_payments (
                        id VARCHAR(36) PRIMARY KEY,
                        store_id VARCHAR(36) NOT NULL,
                        customer_id VARCHAR(36) NOT NULL,
                        method VARCHAR(24) DEFAULT 'CASH',
                        amount NUMERIC(12, 2) NOT NULL,
                        note TEXT,
                        created_by VARCHAR(36),
                        device_id VARCHAR(128),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_customer_payments_store_id "
                    "ON customer_payments(store_id)"
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_customer_payments_customer_id "
                    "ON customer_payments(customer_id)"
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_customer_payments_created_at "
                    "ON customer_payments(created_at)"
                )
            )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "customer_payments",
            "method",
            "ALTER TABLE customer_payments ADD COLUMN method VARCHAR(24) DEFAULT 'CASH'",
        )

        if "sale_refunds" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE sale_refunds (
                        id VARCHAR(36) PRIMARY KEY,
                        store_id VARCHAR(36) NOT NULL,
                        sale_id VARCHAR(36) NOT NULL,
                        amount NUMERIC(12, 2) NOT NULL,
                        reason TEXT,
                        created_by VARCHAR(36),
                        device_id VARCHAR(128),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_sale_refunds_store_id "
                    "ON sale_refunds(store_id)"
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_sale_refunds_sale_id "
                    "ON sale_refunds(sale_id)"
                )
            )

        if "sale_refund_items" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE sale_refund_items (
                        id VARCHAR(36) PRIMARY KEY,
                        refund_id VARCHAR(36) NOT NULL,
                        sale_id VARCHAR(36) NOT NULL,
                        product_id VARCHAR(36) NOT NULL,
                        qty NUMERIC(12, 2) NOT NULL,
                        unit_price NUMERIC(12, 2) NOT NULL,
                        line_total NUMERIC(12, 2) NOT NULL
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_sale_refund_items_refund_id "
                    "ON sale_refund_items(refund_id)"
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_sale_refund_items_sale_id "
                    "ON sale_refund_items(sale_id)"
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_sale_refund_items_product_id "
                    "ON sale_refund_items(product_id)"
                )
            )

        if "sale_payments" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE sale_payments (
                        id VARCHAR(36) PRIMARY KEY,
                        sale_id VARCHAR(36) NOT NULL,
                        method VARCHAR(24) NOT NULL,
                        amount NUMERIC(12, 2) NOT NULL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_sale_payments_sale_id "
                    "ON sale_payments(sale_id)"
                )
            )

        if "stock_movements" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE stock_movements (
                        id VARCHAR(36) PRIMARY KEY,
                        store_id VARCHAR(36) NOT NULL,
                        product_id VARCHAR(36) NOT NULL,
                        movement_type VARCHAR(32) NOT NULL,
                        delta_qty NUMERIC(12, 2) NOT NULL,
                        balance_after NUMERIC(12, 2) NOT NULL,
                        reason TEXT,
                        reference_type VARCHAR(32),
                        reference_id VARCHAR(36),
                        created_by VARCHAR(36),
                        device_id VARCHAR(128),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_stock_movements_product_id "
                    "ON stock_movements(product_id)"
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_stock_movements_store_id "
                    "ON stock_movements(store_id)"
                )
            )

        if "devices" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE devices (
                        device_id VARCHAR(128) PRIMARY KEY,
                        owner_user_id VARCHAR(36) NOT NULL,
                        platform VARCHAR(32) DEFAULT 'unknown',
                        device_model VARCHAR(64),
                        app_version VARCHAR(32),
                        registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_devices_owner_user_id "
                    "ON devices(owner_user_id)"
                )
            )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "devices",
            "device_model",
            "ALTER TABLE devices ADD COLUMN device_model VARCHAR(64)",
        )
        _sqlite_add_column_if_missing(
            conn,
            tables,
            "devices",
            "registered_at",
            "ALTER TABLE devices ADD COLUMN registered_at DATETIME DEFAULT CURRENT_TIMESTAMP",
        )

        if "revoked_tokens" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE revoked_tokens (
                        id VARCHAR(36) PRIMARY KEY,
                        token_hash VARCHAR(64) NOT NULL UNIQUE,
                        token_type VARCHAR(16) DEFAULT 'refresh',
                        expires_at DATETIME NOT NULL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_revoked_tokens_token_hash "
                    "ON revoked_tokens(token_hash)"
                )
            )

        if "ledger_entries" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE ledger_entries (
                        id VARCHAR(36) PRIMARY KEY,
                        store_id VARCHAR(36) NOT NULL,
                        entity_type VARCHAR(32) NOT NULL,
                        entity_id VARCHAR(36) NOT NULL,
                        entry_type VARCHAR(32) NOT NULL,
                        direction VARCHAR(8) NOT NULL,
                        amount NUMERIC(12, 2) NOT NULL,
                        customer_id VARCHAR(36),
                        sale_id VARCHAR(36),
                        created_by VARCHAR(36),
                        device_id VARCHAR(128),
                        metadata_json JSON,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            for index_sql in (
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_store_id ON ledger_entries(store_id)",
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_entity_type ON ledger_entries(entity_type)",
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_entity_id ON ledger_entries(entity_id)",
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_entry_type ON ledger_entries(entry_type)",
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_customer_id ON ledger_entries(customer_id)",
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_sale_id ON ledger_entries(sale_id)",
                "CREATE INDEX IF NOT EXISTS ix_ledger_entries_created_at ON ledger_entries(created_at)",
            ):
                conn.execute(text(index_sql))

        if "customer_metrics" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE customer_metrics (
                        id VARCHAR(36) PRIMARY KEY,
                        store_id VARCHAR(36) NOT NULL,
                        customer_id VARCHAR(36) NOT NULL,
                        outstanding_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
                        oldest_due_days INTEGER NOT NULL DEFAULT 0,
                        avg_days_to_pay NUMERIC(8, 2) NOT NULL DEFAULT 0,
                        on_time_rate NUMERIC(5, 4) NOT NULL DEFAULT 0,
                        payment_frequency_30d NUMERIC(8, 2) NOT NULL DEFAULT 0,
                        risk_score INTEGER NOT NULL DEFAULT 0,
                        risk_level VARCHAR(16) NOT NULL DEFAULT 'green',
                        explanation_json JSON,
                        version INTEGER NOT NULL DEFAULT 1,
                        computed_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            for index_sql in (
                "CREATE INDEX IF NOT EXISTS ix_customer_metrics_store_id ON customer_metrics(store_id)",
                "CREATE INDEX IF NOT EXISTS ix_customer_metrics_customer_id ON customer_metrics(customer_id)",
                "CREATE INDEX IF NOT EXISTS ix_customer_metrics_risk_score ON customer_metrics(risk_score)",
                "CREATE INDEX IF NOT EXISTS ix_customer_metrics_risk_level ON customer_metrics(risk_level)",
                "CREATE INDEX IF NOT EXISTS ix_customer_metrics_computed_at ON customer_metrics(computed_at)",
            ):
                conn.execute(text(index_sql))

        if "alerts" not in tables:
            conn.execute(
                text(
                    """
                    CREATE TABLE alerts (
                        id VARCHAR(36) PRIMARY KEY,
                        store_id VARCHAR(36) NOT NULL,
                        type VARCHAR(32) NOT NULL,
                        entity_type VARCHAR(32) NOT NULL,
                        entity_id VARCHAR(36),
                        severity VARCHAR(16) NOT NULL DEFAULT 'info',
                        title VARCHAR(255) NOT NULL,
                        body VARCHAR(1000) NOT NULL,
                        action_type VARCHAR(64),
                        action_payload_json JSON,
                        resolved_at DATETIME,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
            )
            for index_sql in (
                "CREATE INDEX IF NOT EXISTS ix_alerts_store_id ON alerts(store_id)",
                "CREATE INDEX IF NOT EXISTS ix_alerts_type ON alerts(type)",
                "CREATE INDEX IF NOT EXISTS ix_alerts_entity_type ON alerts(entity_type)",
                "CREATE INDEX IF NOT EXISTS ix_alerts_entity_id ON alerts(entity_id)",
                "CREATE INDEX IF NOT EXISTS ix_alerts_severity ON alerts(severity)",
                "CREATE INDEX IF NOT EXISTS ix_alerts_resolved_at ON alerts(resolved_at)",
                "CREATE INDEX IF NOT EXISTS ix_alerts_created_at ON alerts(created_at)",
            ):
                conn.execute(text(index_sql))


def _sqlite_has_column(conn, table_name: str, column_name: str) -> bool:
    rows = conn.execute(text(f"PRAGMA table_info({table_name})")).mappings().all()
    return any(row["name"] == column_name for row in rows)


def _sqlite_add_column_if_missing(conn, tables: set[str], table: str, column: str, ddl: str) -> None:
    if table in tables and not _sqlite_has_column(conn, table, column):
        conn.execute(text(ddl))
