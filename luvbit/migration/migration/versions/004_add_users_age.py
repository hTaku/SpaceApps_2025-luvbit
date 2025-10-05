"""create manage users table

Revision ID: 004
Revises: 003
Create Date: 2025-07-30 10:01:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('age', sa.Integer(), nullable=True))
    op.add_column('users', sa.Column('sex', sa.String(2), nullable=True))
    op.add_column('users', sa.Column('constellation', sa.String(32), nullable=True))

def downgrade():
    op.drop_column('users', 'age')
    op.drop_column('users', 'sex')
    op.drop_column('users', 'constellation')