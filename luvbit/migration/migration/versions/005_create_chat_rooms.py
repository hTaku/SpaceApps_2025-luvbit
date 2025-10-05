"""create chat rooms table

Revision ID: 003
Revises: 002
Create Date: 2025-10-05 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '005'
down_revision = '004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create chat_rooms table
    op.create_table('chat_rooms',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user1_id', sa.Integer(), nullable=False),
        sa.Column('user2_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['user1_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['user2_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user1_id', 'user2_id', name='unique_user_pair')
    )
    
    # Create index for faster queries
    op.create_index('idx_chat_rooms_user1', 'chat_rooms', ['user1_id'])
    op.create_index('idx_chat_rooms_user2', 'chat_rooms', ['user2_id'])


def downgrade() -> None:
    op.drop_index('idx_chat_rooms_user2', table_name='chat_rooms')
    op.drop_index('idx_chat_rooms_user1', table_name='chat_rooms')
    op.drop_table('chat_rooms')