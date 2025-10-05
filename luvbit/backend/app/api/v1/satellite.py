from fastapi import APIRouter, HTTPException, Depends
from core.security import get_current_user
from schemas.auth import UserInfo
from services.satellite_service import SatelliteService
from typing import List, Dict
from sqlalchemy.orm import Session
from core.db import get_db
from models.user_position import UserPosition

router = APIRouter()

@router.get("/satellites/random")
async def get_random_satellite():
    """ランダムな衛星名を取得"""
    satellite_name = SatelliteService.get_random_satellite_name()
    return {
        "satellite_name": satellite_name,
        "total_satellites": SatelliteService.get_satellite_count()
    }

@router.get("/satellites/all", response_model=List[str])
async def get_all_satellites():
    """すべての衛星名を取得"""
    return SatelliteService.get_all_satellite_names()

@router.get("/satellites/count")
async def get_satellite_count():
    """衛星数を取得"""
    return {
        "count": SatelliteService.get_satellite_count(),
        "is_loaded": SatelliteService._is_loaded
    }

@router.get("/satellites/nearby")
async def get_nearby_satellites(
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    ユーザーの現在位置から1km以内を通る衛星を取得
    
    Args:
        user_id: ユーザーID
        db: データベースセッション
        
    Returns:
        Dict: 近くを通る衛星のリスト
    """
    try:
        # ユーザーの最新位置を取得
        user_position = db.query(UserPosition).filter(
            UserPosition.user_id == current_user.id
        ).order_by(UserPosition.created_at.desc()).first()
        
        if not user_position:
            raise HTTPException(
                status_code=404, 
                detail=f"ユーザーID {current_user.id} の位置情報が見つかりません"
            )
        
        # ユーザーの位置近くを通る衛星を検索
        nearby_satellites = SatelliteService.find_satellites_near_user(
            user_lat=float(user_position.lat),
            user_lng=float(user_position.lng),
            tolerance_km=1.0,
            time_hours=24
        )
        
        return {
            "user_id": current_user.id,
            "user_position": {
                "latitude": float(user_position.lat),
                "longitude": float(user_position.lng),
                "updated_at": user_position.created_at.isoformat()
            },
            "nearby_satellites": nearby_satellites,
            "search_radius_km": 1.0,
            "time_range_hours": 24,
            "note": "現在はランダム選択。軌道計算は今後実装予定"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"衛星検索中にエラーが発生しました: {str(e)}"
        )