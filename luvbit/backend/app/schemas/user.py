from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    """ユーザー作成リクエスト"""
    email: EmailStr
    password: str
    nick_name: str

class UserResponse(BaseModel):
    """ユーザー作成レスポンス"""
    id: int
    email: str
    nick_name: str
    
    class Config:
        from_attributes = True