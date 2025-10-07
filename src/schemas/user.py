from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    fullname: str
    email: EmailStr
    rol: str
    password: str

class UserResponse(BaseModel):
    id_usuario: int
    fullname: str
    email: EmailStr

    class Config:
        from_attributes = True  # reemplazo de orm_mode=True
        orm_mode = False