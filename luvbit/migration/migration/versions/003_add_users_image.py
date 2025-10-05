"""create manage users table

Revision ID: 003
Revises: 002
Create Date: 2025-07-30 10:01:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('profile_image', sa.LargeBinary(), nullable=True))

def downgrade():
    op.drop_column('users', 'profile_image')