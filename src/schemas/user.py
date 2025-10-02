from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    nombre_completo: str
    correo: EmailStr
    rol: str
    contrasena: str

class UserResponse(BaseModel):
    id_usuario: int
    nombre_completo: str
    correo: EmailStr

    class Config:
        from_attributes = True  # reemplazo de orm_mode=True
        orm_mode = False