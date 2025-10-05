from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, text, ForeignKey, Index
from sqlalchemy.orm import relationship

from .base import BaseModel

class Message(BaseModel):
    __tablename__ = 'messages'

    chat_room_id = Column(Integer, ForeignKey('chat_rooms.id', ondelete='CASCADE'), nullable=False)
    sender_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    message_text = Column(Text, nullable=False)
    message_type = Column(String(20), server_default='text', nullable=False)
    is_read = Column(Boolean, server_default=text('false'), nullable=False)
    created_at = Column(TIMESTAMP, nullable=False, server_default=text('CURRENT_TIMESTAMP'))

    # リレーションシップ
    chat_room = relationship("ChatRoom", back_populates="messages")
    sender = relationship("User")

    # インデックス
    __table_args__ = (
        Index('idx_messages_chat_room', 'chat_room_id'),
        Index('idx_messages_sender', 'sender_id'),
        Index('idx_messages_created_at', 'created_at'),
    )