"""create messages table

Revision ID: 004
Revises: 003
Create Date: 2025-10-05 12:01:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '006'
down_revision = '005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create messages table
    op.create_table('messages',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('chat_room_id', sa.Integer(), nullable=False),
        sa.Column('sender_id', sa.Integer(), nullable=False),
        sa.Column('message_text', sa.Text(), nullable=False),
        sa.Column('message_type', sa.String(20), server_default='text', nullable=False),
        sa.Column('is_read', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['chat_room_id'], ['chat_rooms.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['sender_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indexes for faster queries
    op.create_index('idx_messages_chat_room', 'messages', ['chat_room_id'])
    op.create_index('idx_messages_sender', 'messages', ['sender_id'])
    op.create_index('idx_messages_created_at', 'messages', ['created_at'])


def downgrade() -> None:
    op.drop_index('idx_messages_created_at', table_name='messages')
    op.drop_index('idx_messages_sender', table_name='messages')
    op.drop_index('idx_messages_chat_room', table_name='messages')
    op.drop_table('messages')