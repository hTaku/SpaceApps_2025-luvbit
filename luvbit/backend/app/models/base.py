from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine, Column, Integer, TIMESTAMP, text, Engine
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from typing import Generator

from core.db import DB_NAME

class DBSessionManager:
    def __new__(cls):
        if not hasattr(cls, '_instance'):
            cls._instance = super(DBSessionManager, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not hasattr(self, '_initialized'):
            self._engine: Engine = create_engine(
                DB_NAME.get_database_url(), 
                echo=True
            )
            self._session_maker: sessionmaker = sessionmaker(
                autocommit=False, 
                autoflush=False, 
                bind=self._engine
            )
            self._initialized = True

    def initialize(self):
        """
        指定したDB名で設定を初期化
        """
        pass

    def get_db(self) -> Generator[Session, None, None]:
        """
        指定したDB名のセッションを取得
        """
        SessionLocal = self._get_session_maker(DB_NAME)
        db = SessionLocal()
        try:
            yield db
        finally:
            db.close()

Base = declarative_base()

class BaseModel(Base):
    __abstract__ = True
    
    id = Column(Integer, primary_key=True)
    created_at = Column(TIMESTAMP, nullable=False, server_default=text('CURRENT_TIMESTAMP'))

__all__ = ['DBSessionManager', 'BaseModel', 'Base']