from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.service import user_service
from src.schemas.user import UserCreate, UserInDB
from typing import List

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/", response_model=UserInDB)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    return user_service.create_user(db, user)

@router.get("/", response_model=List[UserInDB])
def list_users(db: Session = Depends(get_db)):
    return user_service.get_users(db)
