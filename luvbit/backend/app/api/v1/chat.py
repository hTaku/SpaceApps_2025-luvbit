from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc, func
from typing import List, Optional
import base64

from core.db import get_db
from core.security import get_current_user
from models.user import User
from models.chat_room import ChatRoom
from models.message import Message
from schemas.chat import (
    ChatRoomCreate, ChatRoomInfo, ChatRoomResponse,
    MessageCreate, MessageInfo, MessageListResponse
)
from schemas.auth import UserInfo

router = APIRouter()

@router.post("/rooms", response_model=ChatRoomResponse)
async def create_chat_room(
    request: ChatRoomCreate,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    チャットルームを作成
    
    Args:
        request: チャットルーム作成リクエスト
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        ChatRoomResponse: チャットルーム作成結果
    """
    try:
        # 相手のユーザーが存在するかチェック
        partner_user = db.query(User).filter(User.id == request.partner_user_id).first()
        if not partner_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="指定されたユーザーが見つかりません"
            )
        
        # 自分と同じユーザーとのチャットルーム作成を防ぐ
        if current_user.id == request.partner_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="自分自身とはチャットできません"
            )
        
        # 既存のチャットルームがあるかチェック（双方向チェック）
        existing_room = db.query(ChatRoom).filter(
            or_(
                and_(ChatRoom.user1_id == current_user.id, ChatRoom.user2_id == request.partner_user_id),
                and_(ChatRoom.user1_id == request.partner_user_id, ChatRoom.user2_id == current_user.id)
            )
        ).first()
        
        if existing_room:
            return ChatRoomResponse(
                id=existing_room.id,
                partner_nickname=partner_user.nick_name,
                message="既存のチャットルームを使用します"
            )
        
        # 新しいチャットルームを作成
        # user1_idには小さいID、user2_idには大きいIDを設定して一意性を保つ
        user1_id = min(current_user.id, request.partner_user_id)
        user2_id = max(current_user.id, request.partner_user_id)
        
        new_room = ChatRoom(
            user1_id=user1_id,
            user2_id=user2_id
        )
        
        db.add(new_room)
        db.commit()
        db.refresh(new_room)
        
        return ChatRoomResponse(
            id=new_room.id,
            partner_nickname=partner_user.nick_name,
            message="チャットルームが作成されました"
        )
        
    except Exception as e:
        db.rollback()
        print(f"チャットルーム作成エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"チャットルームの作成に失敗しました: {str(e)}"
        )

@router.get("/rooms", response_model=List[ChatRoomInfo])
async def get_chat_rooms(
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    自分のチャットルーム一覧を取得
    
    Args:
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        List[ChatRoomInfo]: チャットルーム一覧
    """
    try:
        # 自分が参加しているチャットルームを取得
        chat_rooms = db.query(ChatRoom).filter(
            or_(
                ChatRoom.user1_id == current_user.id,
                ChatRoom.user2_id == current_user.id
            )
        ).order_by(desc(ChatRoom.updated_at)).all()
        
        result = []
        for room in chat_rooms:
            # 相手のユーザー情報を取得
            partner = room.get_partner(current_user.id)
            
            # 最新メッセージを取得
            last_message = db.query(Message).filter(
                Message.chat_room_id == room.id
            ).order_by(desc(Message.created_at)).first()
            
            # 未読メッセージ数を取得
            unread_count = db.query(Message).filter(
                and_(
                    Message.chat_room_id == room.id,
                    Message.sender_id != current_user.id,
                    Message.is_read == False
                )
            ).count()
            
            # プロフィール画像をBase64エンコード
            profile_image_base64 = None
            if partner.profile_image:
                try:
                    profile_image_base64 = base64.b64encode(partner.profile_image).decode('utf-8')
                except Exception as e:
                    print(f"Profile image encoding error: {e}")
            
            result.append(ChatRoomInfo(
                id=room.id,
                partner_id=room.get_partner_id(current_user.id),
                partner_nickname=partner.nick_name,
                partner_profile_image=profile_image_base64,
                last_message=last_message.message_text if last_message else None,
                last_message_time=last_message.created_at if last_message else None,
                unread_count=unread_count,
                created_at=room.created_at
            ))
        
        return result
        
    except Exception as e:
        print(f"チャットルーム一覧取得エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"チャットルーム一覧の取得に失敗しました: {str(e)}"
        )

@router.get("/rooms/{room_id}/messages", response_model=MessageListResponse)
async def get_messages(
    room_id: int,
    page: int = Query(1, ge=1, description="ページ番号"),
    limit: int = Query(50, ge=1, le=100, description="1ページあたりのメッセージ数"),
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    チャットルームのメッセージ一覧を取得
    
    Args:
        room_id: チャットルームID
        page: ページ番号
        limit: 1ページあたりのメッセージ数
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        MessageListResponse: メッセージ一覧
    """
    try:
        # チャットルームが存在し、自分が参加者かチェック
        chat_room = db.query(ChatRoom).filter(
            and_(
                ChatRoom.id == room_id,
                or_(
                    ChatRoom.user1_id == current_user.id,
                    ChatRoom.user2_id == current_user.id
                )
            )
        ).first()
        
        if not chat_room:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="チャットルームが見つからないか、アクセス権限がありません"
            )
        
        # メッセージの総数を取得
        total_count = db.query(Message).filter(Message.chat_room_id == room_id).count()
        
        # メッセージを取得（新しい順）
        offset = (page - 1) * limit
        messages = db.query(Message).filter(
            Message.chat_room_id == room_id
        ).order_by(desc(Message.created_at)).offset(offset).limit(limit).all()
        
        # レスポンス用のメッセージリストを作成
        message_list = []
        for msg in messages:
            message_list.append(MessageInfo(
                id=msg.id,
                chat_room_id=msg.chat_room_id,
                sender_id=msg.sender_id,
                sender_nickname=msg.sender.nick_name,
                message_text=msg.message_text,
                message_type=msg.message_type,
                is_read=msg.is_read,
                created_at=msg.created_at,
                is_mine=(msg.sender_id == current_user.id)
            ))
        
        return MessageListResponse(
            messages=message_list,
            total_count=total_count
        )
        
    except Exception as e:
        print(f"メッセージ一覧取得エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"メッセージ一覧の取得に失敗しました: {str(e)}"
        )

@router.post("/rooms/{room_id}/messages", response_model=MessageInfo)
async def send_message(
    room_id: int,
    request: MessageCreate,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    メッセージを送信
    
    Args:
        room_id: チャットルームID
        request: メッセージ作成リクエスト
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        MessageInfo: 送信されたメッセージ情報
    """
    try:
        # チャットルームが存在し、自分が参加者かチェック
        chat_room = db.query(ChatRoom).filter(
            and_(
                ChatRoom.id == room_id,
                or_(
                    ChatRoom.user1_id == current_user.id,
                    ChatRoom.user2_id == current_user.id
                )
            )
        ).first()
        
        if not chat_room:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="チャットルームが見つからないか、アクセス権限がありません"
            )
        
        # メッセージを作成
        new_message = Message(
            chat_room_id=room_id,
            sender_id=current_user.id,
            message_text=request.message_text,
            message_type=request.message_type
        )
        
        db.add(new_message)
        
        # チャットルームの更新日時を更新
        chat_room.updated_at = func.now()
        
        db.commit()
        db.refresh(new_message)
        
        # 送信者の情報を取得
        sender = db.query(User).filter(User.id == current_user.id).first()
        
        return MessageInfo(
            id=new_message.id,
            chat_room_id=new_message.chat_room_id,
            sender_id=new_message.sender_id,
            sender_nickname=sender.nick_name,
            message_text=new_message.message_text,
            message_type=new_message.message_type,
            is_read=new_message.is_read,
            created_at=new_message.created_at,
            is_mine=True
        )
        
    except Exception as e:
        db.rollback()
        print(f"メッセージ送信エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"メッセージの送信に失敗しました: {str(e)}"
        )

@router.put("/messages/{message_id}/read")
async def mark_message_as_read(
    message_id: int,
    current_user: UserInfo = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    メッセージを既読にする
    
    Args:
        message_id: メッセージID
        current_user: ログイン中のユーザー情報
        db: データベースセッション
    
    Returns:
        dict: 処理結果
    """
    try:
        # メッセージが存在し、自分宛てかチェック
        message = db.query(Message).filter(Message.id == message_id).first()
        
        if not message:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="メッセージが見つかりません"
            )
        
        # チャットルームの参加者かチェック
        chat_room = db.query(ChatRoom).filter(
            and_(
                ChatRoom.id == message.chat_room_id,
                or_(
                    ChatRoom.user1_id == current_user.id,
                    ChatRoom.user2_id == current_user.id
                )
            )
        ).first()
        
        if not chat_room:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="このメッセージにアクセスする権限がありません"
            )
        
        # 自分のメッセージでない場合のみ既読にする
        if message.sender_id != current_user.id:
            message.is_read = True
            db.commit()
        
        return {"message": "メッセージを既読にしました"}
        
    except Exception as e:
        db.rollback()
        print(f"既読更新エラー: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"既読の更新に失敗しました: {str(e)}"
        )