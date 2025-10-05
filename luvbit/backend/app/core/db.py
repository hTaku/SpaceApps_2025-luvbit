import os
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
import logging
import time

logger = logging.getLogger(__name__)

# SQLAlchemy側のコネクション設定
class DatabaseConfig:
    # コネクションプール設定
    POOL_SIZE = int(os.getenv('DB_POOL_SIZE', '10'))           # 通常時のプールサイズ
    MAX_OVERFLOW = int(os.getenv('DB_MAX_OVERFLOW', '20'))     # 追加接続数
    POOL_TIMEOUT = int(os.getenv('DB_POOL_TIMEOUT', '30'))     # 接続待ちタイムアウト
    POOL_RECYCLE = int(os.getenv('DB_POOL_RECYCLE', '3600'))   # 接続リサイクル間隔（1時間）
    POOL_PRE_PING = True                                       # 接続前ヘルスチェック
    
    # 接続パラメータ
    CONNECT_TIMEOUT = 30
    
    # ログ設定
    ECHO_SQL = os.getenv('DB_ECHO', 'false').lower() == 'true'

# データベース接続設定
## Manage DB
DB_HOST = os.getenv('DB_HOST', 'luvbit-db')
DB_PORT = int(os.getenv('DB_PORT', '5432'))  # ← 文字列を明示してintに変換
DB_NAME = os.getenv('DB_NAME', 'luvbit_db')
DB_USER = os.getenv('DB_USER', 'luvbit')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'luvbit')

# データベースURLの正しい構築（f-string使用）
def build_database_urls():
    """データベースURLを動的に構築"""
    # 環境変数から直接取得を優先し、なければ構築
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        database_url = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/luvbit_db'
    
    return database_url

# データベースURLを取得
DATABASE_URL = build_database_urls()

# デバッグ用ログ出力
logger.info(f"データベースURL設定完了:")
logger.info(f"DB: {DATABASE_URL.replace(DB_PASSWORD, '***')}")  # パスワードをマスク

def create_optimized_engine(database_url: str, engine_type: str = "standard"):
    """最適化されたエンジンを作成"""
    
    # エンジンタイプに応じて設定を調整
    pool_size = DatabaseConfig.POOL_SIZE
    max_overflow = DatabaseConfig.MAX_OVERFLOW
    pool_timeout = DatabaseConfig.POOL_TIMEOUT
    app_name_suffix = "standard"
    
    logger.info(f"エンジン作成 ({engine_type}): プールサイズ={pool_size}, オーバーフロー={max_overflow}")
    logger.debug(f"接続URL: {database_url}")
    
    engine = create_engine(
        database_url,
        
        # プール設定
        poolclass=QueuePool,
        pool_size=pool_size,
        max_overflow=max_overflow,
        pool_timeout=pool_timeout,
        pool_recycle=DatabaseConfig.POOL_RECYCLE,
        pool_pre_ping=DatabaseConfig.POOL_PRE_PING,
        
        # パフォーマンス設定
        echo=DatabaseConfig.ECHO_SQL,
        future=True,
        
        # 接続設定（修正版）
        connect_args={
            "application_name": f"yoride_shop_{app_name_suffix}",
            "connect_timeout": DatabaseConfig.CONNECT_TIMEOUT,
            # PostgreSQLのオプション設定
            "options": f"-c timezone=UTC -c statement_timeout=300000 -c idle_in_transaction_session_timeout=600000"
        },
        
        # 追加のエンジン設定
        pool_reset_on_return='commit',  # 返却時にcommit
        isolation_level="READ_COMMITTED"
    )
    
    # エンジンイベントリスナー（接続監視用）
    @event.listens_for(engine, "connect")
    def set_connection_settings(dbapi_connection, connection_record):
        """接続時の設定"""
        connection_record.info['connect_time'] = time.time()
        logger.debug(f"新規DB接続作成: {engine_type}")
        
        # 接続レベルでの追加設定
        with dbapi_connection.cursor() as cursor:
            try:
                # SSE用の接続では長時間のクエリタイムアウトを設定
                if engine_type == "sse":
                    cursor.execute("SET statement_timeout = '600000'")  # 10分
                    cursor.execute("SET idle_in_transaction_session_timeout = '1800000'")  # 30分
                else:
                    cursor.execute("SET statement_timeout = '300000'")  # 5分
                    cursor.execute("SET idle_in_transaction_session_timeout = '600000'")  # 10分
                
                # 共通設定
                cursor.execute("SET timezone = 'UTC'")
                cursor.execute("SET lock_timeout = '30000'")  # 30秒
                cursor.execute("SET deadlock_timeout = '1000'")  # 1秒
                
            except Exception as e:
                logger.warning(f"接続設定エラー: {e}")
    
    return engine

# 標準エンジン（通常のAPI用）
try:
    engine = create_optimized_engine(DATABASE_URL, "standard")
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    logger.info("DB標準エンジン作成完了")
except Exception as e:
    logger.error(f"DB標準エンジン作成エラー: {e}")
    raise

# セッション取得関数
def get_db():
    """標準DB接続"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
