"""add otp challenges

Revision ID: 20260304_131500
Revises: 20260228_120000
Create Date: 2026-03-04 13:15:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260304_131500"
down_revision = "20260228_120000"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_tables = set(inspector.get_table_names())
    existing_indexes = {
        idx.get("name")
        for idx in inspector.get_indexes("otp_challenges")
    } if "otp_challenges" in existing_tables else set()

    if "otp_challenges" not in existing_tables:
        op.create_table(
            "otp_challenges",
            sa.Column("id", sa.String(length=36), nullable=False),
            sa.Column("phone", sa.String(length=32), nullable=False),
            sa.Column("otp_hash", sa.String(), nullable=False),
            sa.Column(
                "locale_default",
                sa.String(length=16),
                nullable=False,
                server_default="ne",
            ),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column(
                "verify_attempts",
                sa.Integer(),
                nullable=False,
                server_default="0",
            ),
            sa.Column(
                "is_new_user_hint",
                sa.Boolean(),
                nullable=False,
                server_default=sa.true(),
            ),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.text("CURRENT_TIMESTAMP"),
            ),
            sa.PrimaryKeyConstraint("id"),
        )
        existing_indexes = set()

    if "ix_otp_challenges_phone" not in existing_indexes:
        op.create_index(
            "ix_otp_challenges_phone",
            "otp_challenges",
            ["phone"],
            unique=False,
        )
    if "ix_otp_challenges_expires_at" not in existing_indexes:
        op.create_index(
            "ix_otp_challenges_expires_at",
            "otp_challenges",
            ["expires_at"],
            unique=False,
        )


def downgrade() -> None:
    op.drop_index("ix_otp_challenges_expires_at", table_name="otp_challenges")
    op.drop_index("ix_otp_challenges_phone", table_name="otp_challenges")
    op.drop_table("otp_challenges")
