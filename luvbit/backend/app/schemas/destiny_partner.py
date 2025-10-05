from pydantic import BaseModel
from typing import Optional

class DestinyPartnerRequest(BaseModel):
    """運命のパートナー検索リクエスト"""
    satellite_name: str

class DestinyPartnerResponse(BaseModel):
    """運命のパートナー検索レスポンス"""
    user_id: Optional[int] = None
    nickname: Optional[str] = None
    profile_image: Optional[str] = None
    age: Optional[int] = None
    sex: Optional[str] = None
    constellation: Optional[str] = None
    message: str = "運命のパートナーが見つかりました"
    
    class Config:
        from_attributes = True