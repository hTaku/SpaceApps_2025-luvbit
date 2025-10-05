from sqlalchemy import Column, Integer, Float, TIMESTAMP, text, ForeignKey

from .base import BaseModel

class UserPosition(BaseModel):
    __tablename__ = 'user_positions'

    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, unique=True)
    lng = Column(Float, nullable=False)
    lat = Column(Float, nullable=False)
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    
    # リレーションシップ（必要に応じて）
    # user = relationship("User", back_populates="position")