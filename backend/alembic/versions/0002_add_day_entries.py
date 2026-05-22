"""add day_entries table

Revision ID: 0002_add_day_entries
Revises: 0001_add_gym_sessions
Create Date: 2026-05-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '0002_add_day_entries'
down_revision = '0001_add_gym_sessions'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'day_entries',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('content', sa.String(300), nullable=False),
        sa.Column('category', sa.String(30), nullable=False, server_default='personal'),
        sa.Column('emoji', sa.String(10), nullable=True),
        sa.Column('source', sa.String(20), nullable=False, server_default='manual'),
        sa.Column('source_ref_id', sa.String(100), nullable=True),
        sa.Column('date', sa.Date(), nullable=False, index=True),
        sa.Column('logged_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table('day_entries')
