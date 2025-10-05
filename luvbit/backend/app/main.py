from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.v1 import api_router
from services.satellite_service import SatelliteService

app = FastAPI(
    title="Luvbit API",
    version="1.0.0",
    openapi_url="/api/v1/openapi.json"
)

# 衛星データの初期化
@app.on_event("startup")
async def startup_event():
    """アプリケーション起動時の処理"""
    print("Luvbit API起動中...")
    # TLEファイルから衛星名を読み込み
    success = SatelliteService.load_satellite_names()
    if success:
        print(f"衛星データを読み込みました。衛星数: {SatelliteService.get_satellite_count()}")
    else:
        print("衛星データの読み込みに失敗しました。デフォルトデータを使用します。")

# CORS設定を追加
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 本番環境では具体的なオリジンを指定
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")
