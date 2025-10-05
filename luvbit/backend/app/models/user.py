from sqlalchemy import Column, Integer, LargeBinary, String, TIMESTAMP, text

from .base import BaseModel

class User(BaseModel):
    __tablename__ = 'users'

    uuid = Column(String(255), nullable=False, unique=True)
    email = Column(String(255), nullable=False, unique=True)
    password = Column(String(255), nullable=False)
    nick_name = Column(String(32), nullable=False)
    profile_image = Column(LargeBinary, nullable=True)
    age = Column(Integer, nullable=False, default=None)
    sex = Column(Integer, nullable=False, default=None)
    constellation = Column(String(32), nullable=False, default=None)
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text('CURRENT_TIMESTAMP'))