from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class ChatRoomCreate(BaseModel):
    """チャットルーム作成リクエスト"""
    partner_user_id: int

class ChatRoomInfo(BaseModel):
    """チャットルーム情報"""
    id: int
    partner_id: int
    partner_nickname: str
    partner_profile_image: Optional[str] = None
    last_message: Optional[str] = None
    last_message_time: Optional[datetime] = None
    unread_count: int = 0
    created_at: datetime
    
    class Config:
        from_attributes = True

class MessageCreate(BaseModel):
    """メッセージ作成リクエスト"""
    message_text: str
    message_type: str = "text"

class MessageInfo(BaseModel):
    """メッセージ情報"""
    id: int
    chat_room_id: int
    sender_id: int
    sender_nickname: str
    message_text: str
    message_type: str
    is_read: bool
    created_at: datetime
    is_mine: bool = False  # 自分のメッセージかどうか
    
    class Config:
        from_attributes = True

class ChatRoomResponse(BaseModel):
    """チャットルーム作成レスポンス"""
    id: int
    partner_nickname: str
    message: str = "チャットルームが作成されました"
    
    class Config:
        from_attributes = True

class MessageListResponse(BaseModel):
    """メッセージ一覧レスポンス"""
    messages: List[MessageInfo]
    total_count: int
    
    class Config:
        from_attributes = True