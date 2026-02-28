"""baseline existing schema

Revision ID: 20260228_120000
Revises:
Create Date: 2026-02-28 12:00:00
"""

from __future__ import annotations


revision = "20260228_120000"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Baseline revision for an existing deployed schema.
    # Stamp current databases with this revision before using future migrations.
    pass


def downgrade() -> None:
    pass
