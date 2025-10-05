from fastapi import APIRouter
from .auth import router as auth_router
from .user import router as user_router
from .user_position import router as user_position_router
from .satellite import router as satellite_router
from .destiny_partner import router as destiny_partner_router
from .chat import router as chat_router

api_router = APIRouter()
api_router.include_router(auth_router, prefix="", tags=["auth"])
api_router.include_router(user_router, prefix="", tags=["user"])
api_router.include_router(user_position_router, prefix="", tags=["user_position"])
api_router.include_router(satellite_router, prefix="", tags=["satellite"])
api_router.include_router(destiny_partner_router, prefix="", tags=["destiny_partner"])
api_router.include_router(chat_router, prefix="/chat", tags=["chat"])
