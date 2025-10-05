from pydantic import BaseModel
from typing import Optional

class UserPositionRequest(BaseModel):
    """位置情報登録リクエスト"""
    lat: float
    lng: float

class UserPositionResponse(BaseModel):
    """位置情報登録レスポンス"""
    user_id: int
    lat: float
    lng: float
    
    class Config:
        from_attributes = True