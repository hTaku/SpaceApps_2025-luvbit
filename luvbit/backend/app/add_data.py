from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from core.db import get_db
from models.user import User
import os

# --- DB接続設定（例：PostgreSQL） ---
DATABASE_URL = "postgresql+psycopg2://luvbit:luvbit@localhost:5432/luvbit_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

def insert_image(image_path: str):
    """画像ファイルをBLOBカラムに挿入する関数"""
    session = next(get_db())

    try:
        # ファイルをバイナリとして読み込む
        with open(image_path, "rb") as f:
            image_data = f.read()

        # Imageオブジェクト作成
        user = session.query(User).filter(User.id == 1).first()
        user.profile_image = image_data

        # DBに追加
        session.commit()

    except Exception as e:
        session.rollback()
        print("❌ エラー:", e)

    finally:
        session.close()

if __name__ == "__main__":
    # 保存したい画像ファイルを指定
    image_path = "./images/0.png"
    if os.path.exists(image_path):
        insert_image(image_path)
    else:
        print(f"⚠️ ファイルが見つかりません: {image_path}")
