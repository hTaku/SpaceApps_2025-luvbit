from sqlalchemy import Column, Integer, String, TIMESTAMP, text, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship

from .base import BaseModel

class ChatRoom(BaseModel):
    __tablename__ = 'chat_rooms'

    user1_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    user2_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    created_at = Column(TIMESTAMP, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text('CURRENT_TIMESTAMP'))

    # リレーションシップ
    user1 = relationship("User", foreign_keys=[user1_id])
    user2 = relationship("User", foreign_keys=[user2_id])
    messages = relationship("Message", back_populates="chat_room", cascade="all, delete-orphan")

    # 制約
    __table_args__ = (
        UniqueConstraint('user1_id', 'user2_id', name='unique_user_pair'),
        Index('idx_chat_rooms_user1', 'user1_id'),
        Index('idx_chat_rooms_user2', 'user2_id'),
    )

    def get_partner_id(self, current_user_id: int) -> int:
        """現在のユーザーの相手のIDを取得"""
        if self.user1_id == current_user_id:
            return self.user2_id
        return self.user1_id

    def get_partner(self, current_user_id: int):
        """現在のユーザーの相手のユーザー情報を取得"""
        if self.user1_id == current_user_id:
            return self.user2
        return self.user1