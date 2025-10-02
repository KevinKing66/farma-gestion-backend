from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.controllers import user_controller
from src.schemas.user import UserCreate, UserResponse
from typing import List

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    return user_controller.create_user(db, user)

@router.get("/", response_model=List[UserResponse])
def list_users(db: Session = Depends(get_db)):
    return user_controller.get_users(db)
