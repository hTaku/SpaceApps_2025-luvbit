from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from core.db import get_db
from core.security import get_current_user
from models.user_position import UserPosition
from schemas.user_position import UserPositionRequest, UserPositionResponse
from schemas.auth import UserInfo

router = APIRouter()

@router.post("/regist_user_position", response_model=UserPositionResponse)
async def regist_user_position(
    position_data: UserPositionRequest,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    ユーザーの位置情報を登録・更新する
    
    Args:
        position_data: 位置情報データ（緯度・経度）
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        UserPositionResponse: 登録・更新された位置情報
        
    Raises:
        HTTPException: データベースエラーが発生した場合
    """
    try:
        # 既存の位置情報を検索
        existing_position = db.query(UserPosition).filter(
            UserPosition.user_id == current_user.id
        ).first()
        
        if existing_position:
            # 既存データの更新
            existing_position.lat = position_data.lat
            existing_position.lng = position_data.lng
            existing_position.updated_at = datetime.utcnow()
            
            db.commit()
            db.refresh(existing_position)
            
            return UserPositionResponse(
                user_id=existing_position.user_id,
                lat=existing_position.lat,
                lng=existing_position.lng
            )
        else:
            # 新規データの作成
            new_position = UserPosition(
                user_id=current_user.id,
                lat=position_data.lat,
                lng=position_data.lng
            )
            
            db.add(new_position)
            db.commit()
            db.refresh(new_position)
            
            return UserPositionResponse(
                user_id=new_position.user_id,
                lat=new_position.lat,
                lng=new_position.lng
            )
            
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"位置情報の登録に失敗しました: {str(e)}"
        )