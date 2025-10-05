from abc import ABC, abstractmethod
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from configparser import ConfigParser

class BaseSeeder(ABC):
    def __init__(self):
        # alembic.iniから接続URLを取得
        config = ConfigParser()
        config.read('alembic.ini')
        sqlalchemy_url = config.get('alembic', 'sqlalchemy.url')

        # SQLAlchemyエンジンとセッションの作成
        self.engine = create_engine(sqlalchemy_url)
        Session = sessionmaker(bind=self.engine)
        self.session = Session()

    @abstractmethod
    def run(self):
        """シーダーの実行メソッド"""
        pass

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.session.close()