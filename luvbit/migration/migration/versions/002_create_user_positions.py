"""create manage users table

Revision ID: 002
Revises: 001
Create Date: 2025-07-30 10:01:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'user_positions',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('user_id', sa.Integer, nullable=False),
        sa.Column('lng', sa.Float, nullable=False),
        sa.Column('lat', sa.Float, nullable=False),
        sa.Column('created_at', sa.TIMESTAMP, nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP, nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
    )
    
    # ユニーク制約の追加
    op.create_unique_constraint('uq_user_positions_user_id', 'user_positions', ['user_id'])
    
    # Foreign Key制約の追加（usersテーブルが存在する場合）
    op.create_foreign_key('fk_user_positions_user_id', 'user_positions', 'users', ['user_id'], ['id'])

def downgrade():
    # 制約を削除してからテーブルを削除
    op.drop_constraint('fk_user_positions_user_id', 'user_positions', type_='foreignkey')
    op.drop_constraint('uq_user_positions_user_id', 'user_positions', type_='unique')
    op.drop_table('user_positions')