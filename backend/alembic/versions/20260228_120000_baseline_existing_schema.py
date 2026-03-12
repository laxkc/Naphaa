"""baseline existing schema

Revision ID: 20260228_120000
Revises:
Create Date: 2026-02-28 12:00:00
"""

from __future__ import annotations

from alembic import op

from app import models as _models  # noqa: F401
from app.core.database import Base

revision = "20260228_120000"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Bootstrap baseline schema for fresh databases.
    # Existing deployments can still use `alembic stamp 20260228_120000`.
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)


def downgrade() -> None:
    pass
