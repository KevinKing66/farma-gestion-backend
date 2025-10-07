from pydantic import BaseModel, Field, EmailStr
from typing import Optional

class UserBase(BaseModel):
    fullname: str
    email: EmailStr
    

class UserCreate(UserBase):
    fullname: str
    email: EmailStr
    rol: str
    password: str = Field(..., min_length=6)
    
class UserUpdate(UserBase):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = Field(None, max_length=100)
    password: Optional[str] = Field(None, min_length=6)

class UserInDB(UserBase):
    id: int
    password_hash: str

    class Config:
        from_attributes = True  # reemplazo de orm_mode=True
        orm_mode = False

class UserPublic(UserBase):
    id: int

    class Config:
        from_attributes = True  # reemplazo de orm_mode=True
        orm_mode = False
        