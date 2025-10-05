from pydantic import BaseModel

class Token(BaseModel):
    """トークンレスポンス"""
    access_token: str
    token_type: str
    user_id: int

    class Config:
        from_attributes = True
        
class TokenPayload(BaseModel):
    sub: str  # email
    exp: int  # 有効期限

class UserInfo(BaseModel):
    id: int
    uuid: str
    email: str
    nick_name: str

    class Config:
        from_attributes = True