"""add vault_profiles and vault_records tables

Revision ID: 0003_add_vault
Revises: 0002_add_day_entries
Create Date: 2026-05-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '0003_add_vault'
down_revision = '0002_add_day_entries'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'vault_profiles',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('birth_date', sa.Date(), nullable=True),
        sa.Column('relationship_label', sa.String(50), nullable=True),
        sa.Column('avatar_emoji', sa.String(10), server_default='👶'),
        sa.Column('pin_hash', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        'vault_records',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('profile_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('vault_profiles.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('event_date', sa.Date(), nullable=False, index=True),
        sa.Column('event_type', sa.String(30), nullable=False, server_default='milestone'),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('emoji', sa.String(10), nullable=True),
        sa.Column('weight_kg', sa.Numeric(5, 2), nullable=True),
        sa.Column('height_cm', sa.Numeric(5, 1), nullable=True),
        sa.Column('photo_url', sa.Text(), nullable=True),
        sa.Column('age_years', sa.Integer(), nullable=True),
        sa.Column('age_months', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table('vault_records')
    op.drop_table('vault_profiles')
