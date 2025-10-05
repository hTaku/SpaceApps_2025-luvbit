from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Form
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from core.security import verify_password, create_access_token
from core.db import get_db
from models.user import User
from schemas.auth import Token
from services.satellite_service import SatelliteService

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"login")

@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends()
):
    """
    ユーザーログイン処理
    
    Args:
        form_data: ログインフォームデータ
    """

    db_session = next(get_db())

    try:
        # ユーザー情報の取得
        user = db_session.query(User).filter(
            User.email == form_data.username
        ).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # パスワードの検証
        if not verify_password(form_data.password, user.password):            
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # JWTトークンの生成（ペイロードに店舗UUIDとユーザーIDを含める）
        access_token_expires = timedelta(minutes=30)
        access_token = create_access_token(
            data={
                "sub": user.email,
                "user_id": user.id
            },
            expires_delta=access_token_expires
        )

        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id,
        }

    finally:
        db_session.close()


@router.post("/validate")
async def validate_token(
    token: str = Form(...),
    response_model=Token
):
    """
    トークン検証処理
    
    Args:
        token: 検証対象のJWTトークン
    
    Returns:
        dict: ユーザー情報と店舗情報
    """
    try:
        # JWTトークンをデコード
        payload = jwt.decode(
            token, 
            "your-secret-key-here", 
            algorithms=["HS256"]
        )
        
        # トークンから情報を取得
        email: str = payload.get("sub")
        user_id: int = payload.get("user_id")
        
        if email is None or user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
                
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 店舗DBセッションの取得
    db_session = next(get_db())
    
    try:
        # 店舗ユーザー情報の取得
        user = db_session.query(User).filter(
            User.email == email,
            User.id == user_id
        ).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # アクティブなユーザーかチェック（shop_userにstatusがある場合）
        if hasattr(user, 'status') and user.status != 1:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is inactive",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # レスポンスデータの構築
        response_data = {
            "user_id": user.id,
            "nick_name": f"{user.nick_name}",
            "email": user.email
        }
        
        return response_data
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error: {str(e)}"
        )
    finally:
        db_session.close()


def get_current_user(
    token: str = Depends(oauth2_scheme)
):
    """
    現在のユーザーを取得するヘルパー関数
    
    Args:
        token: JWTトークン
        client_id: 店舗識別子
    
    Returns:
        ShopUser: 現在のユーザー情報
    """
    try:
        # JWTトークンをデコード
        payload = jwt.decode(
            token, 
            "your-secret-key-here", 
            algorithms=["HS256"]
        )
        
        user_id: int = payload.get("user_id")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
                    
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 店舗DBセッションの取得
    db_session = next(get_db())
    
    try:
        # 店舗ユーザー情報の取得
        user = db_session.query(User).filter(
            User.id == user_id
        ).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return user
        
    finally:
        db_session.close()