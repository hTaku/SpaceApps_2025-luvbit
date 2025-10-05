from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
import random
import base64

from core.db import get_db
from core.security import get_current_user
from models.user import User
from models.user_position import UserPosition
from schemas.destiny_partner import DestinyPartnerResponse
from schemas.auth import UserInfo
from services.satellite_service import SatelliteService

router = APIRouter()

@router.get("/debug/user_positions")
async def debug_user_positions(
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """デバッグ用: 全ユーザーの位置情報を表示"""
    try:
        user_positions = db.query(
            UserPosition.user_id,
            UserPosition.lat,
            UserPosition.lng,
            User.nick_name
        ).join(
            User, UserPosition.user_id == User.id
        ).all()
        
        result = []
        for pos in user_positions:
            result.append({
                'user_id': pos.user_id,
                'nickname': pos.nick_name,
                'lat': pos.lat,
                'lng': pos.lng
            })
        
        return {
            'total_users': len(result),
            'users': result
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"ユーザー位置情報の取得に失敗しました: {str(e)}"
        )

@router.get("/debug/satellite_track")
async def debug_satellite_track(
    satellite_name: str = Query(..., description="衛星名"),
    current_user: UserInfo = Depends(get_current_user)
):
    """デバッグ用: 衛星の軌道を表示"""
    try:
        ground_track = SatelliteService.calculate_satellite_ground_track(satellite_name, hours=24)
        
        return {
            'satellite_name': satellite_name,
            'track_points': len(ground_track),
            'ground_track': ground_track[:10] if ground_track else []  # 最初の10ポイントのみ表示
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"衛星軌道の取得に失敗しました: {str(e)}"
        )

@router.get("/get_destiny_partner", response_model=DestinyPartnerResponse)
async def get_destiny_partner(
    satellite_name: str = Query(..., description="衛星名"),
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    運命のパートナーを見つける
    
    Args:
        satellite_name: 衛星名
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        DestinyPartnerResponse: 運命のパートナー情報
        
    Raises:
        HTTPException: エラーが発生した場合
    """
    try:
        print(f"運命のパートナー検索開始: 衛星={satellite_name}, ユーザー={current_user.id}")
        
        # 1. 衛星の軌道を計算
        print("衛星軌道を計算中...")
        ground_track = SatelliteService.calculate_satellite_ground_track(satellite_name, hours=24)
        
        if not ground_track:
            return DestinyPartnerResponse(
                message=f"衛星 '{satellite_name}' の軌道データが見つかりません"
            )
        
        print(f"軌道ポイント数: {len(ground_track)}")
        
        # 2. 自分以外のユーザーの位置情報を取得
        user_positions_query = db.query(
            UserPosition.user_id,
            UserPosition.lat,
            UserPosition.lng,
            User.nick_name,
            User.profile_image,
            User.age,
            User.sex,
            User.constellation
        ).join(
            User, UserPosition.user_id == User.id
        ).filter(
            UserPosition.user_id != current_user.id  # 自分以外
        )
        
        user_positions = user_positions_query.all()
        print(f"検索対象ユーザー数: {len(user_positions)}")
        
        if not user_positions:
            return DestinyPartnerResponse(
                message="他のユーザーが見つかりません"
            )
        
        # 3. 位置情報をリスト形式に変換
        user_position_list = []
        for pos in user_positions:
            user_position_list.append({
                'user_id': pos.user_id,
                'lat': pos.lat,
                'lng': pos.lng,
                'nickname': pos.nick_name,
                'profile_image': pos.profile_image,
                'age': pos.age,
                'sex': pos.sex,
                'constellation': pos.constellation
            })
        
        # 4. 衛星軌道近くにいるユーザーを検索
        print("軌道近くのユーザーを検索中...")
        matched_users = SatelliteService.find_users_near_ground_track(
            ground_track=ground_track,
            user_positions=user_position_list,
            tolerance_km=1.0  # 1km以内
        )
        
        print(f"マッチしたユーザー数: {len(matched_users)}")
        
        if not matched_users:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"'{satellite_name}'はあなたと運命の出会いをもたらしませんでした"
            )
        
        # 5. ランダムに1ユーザーを選択
        selected_user = random.choice(matched_users)
        
        print(f"選択されたパートナー: user_id={selected_user['user_id']}, nickname={selected_user['nickname']}")
        
        # profile_imageをBase64エンコード
        profile_image_base64 = None
        if selected_user.get('profile_image'):
            try:
                profile_image_base64 = base64.b64encode(selected_user['profile_image']).decode('utf-8')
            except Exception as e:
                print(f"Profile image encoding error: {e}")
        
        return DestinyPartnerResponse(
            user_id=selected_user['user_id'],
            nickname=selected_user['nickname'],
            profile_image=profile_image_base64,
            age=selected_user['age'],
            sex=selected_user['sex'],
            constellation=selected_user['constellation'],
            message=f"'{satellite_name}' の軌道が運命の出会いをもたらしました！"
        )
        
    except Exception as e:
        print(f"運命のパートナー検索エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"運命のパートナーの検索に失敗しました: {str(e)}"
        )