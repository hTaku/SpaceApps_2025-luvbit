from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Union
from jose import JWTError, jwt

from models.user import User
from schemas.auth import UserInfo

from core.db import get_db


oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"v1/login")


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """パスワードを検証する"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """パスワードをハッシュ化する"""
    return pwd_context.hash(password)

def create_access_token(
    data: dict, expires_delta: Union[timedelta, None] = None
) -> str:
    """アクセストークンを作成する"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, "your-secret-key-here", algorithm="HS256")
    return encoded_jwt

async def get_current_user(
    token: str = Depends(oauth2_scheme),
) -> UserInfo:
    """
    現在のログインユーザーを取得する
    
    Args:
        token: JWTトークン
        db: データベースセッション
    
    Returns:
        User: ログインユーザー情報
        
    Raises:
        HTTPException: トークンが無効な場合や、ユーザーが見つからない場合
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, "your-secret-key-here", algorithms=["HS256"])
        email: str = payload.get("sub")
    except JWTError:
        raise credentials_exception

    db = next(get_db())
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    
    return UserInfo(
        id=user.id,
        uuid=user.uuid,
        email=user.email,
        nick_name=user.nick_name
    )