import uuid
import base64
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from core.db import get_db
from core.security import get_password_hash, get_current_user
from models.user import User
from schemas.user import UserCreate, UserResponse
from schemas.auth import UserInfo

router = APIRouter()

@router.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """
    ユーザーを作成する
    
    Args:
        user_data: 作成するユーザーデータ
        db: DBセッション
    
    Returns:
        UserResponse: 作成されたユーザー情報
    """
    try:
        # 既存ユーザーの重複チェック
        existing_user = db.query(User).filter(
            User.email == user_data.email
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this email already exists"
            )

        # パスワードをハッシュ化
        hashed_password = get_password_hash(user_data.password)

        # 新しいユーザーを作成
        db_user = User(
            uuid=str(uuid.uuid4()),
            email=user_data.email,
            password=hashed_password,
            nick_name=user_data.nick_name,
        )

        # DBに追加してコミット
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # レスポンスを作成
        return UserResponse(
            id=db_user.id,
            email=db_user.email,
            nick_name=db_user.nick_name,
        )

    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating user: {str(e)}"
        )
    finally:
        db.close()

@router.get("/user_info")
async def get_user_info(
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    ログイン中のユーザー情報を取得する
    
    Args:
        current_user: ログイン中のユーザー情報
        db: DBセッション
    
    Returns:
        dict: ユーザー情報（プロフィール画像を含む）
    """
    try:
        # ユーザー情報を取得
        user = db.query(User).filter(User.id == current_user.id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="ユーザーが見つかりません"
            )
        
        # プロフィール画像をBase64エンコード
        profile_image_base64 = None
        if user.profile_image:
            try:
                profile_image_base64 = base64.b64encode(user.profile_image).decode('utf-8')
            except Exception as e:
                print(f"Profile image encoding error: {e}")
        
        return {
            "id": user.id,
            "uuid": user.uuid,
            "email": user.email,
            "nick_name": user.nick_name,
            "profile_image": profile_image_base64,
            "age": user.age,
            "sex": user.sex,
            "constellation": user.constellation,
        }
        
    except Exception as e:
        print(f"ユーザー情報取得エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"ユーザー情報の取得に失敗しました: {str(e)}"
        )