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
    op.create_index(
        "ix_otp_challenges_phone",
        "otp_challenges",
        ["phone"],
        unique=False,
    )
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
