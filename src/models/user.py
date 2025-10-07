from pydantic import BaseModel, Field, EmailStr
from typing import Optional

class User(BaseModel):
    id: Optional[int] = Field(default=None, description="ID autogenerado del usuario", alias="id_usuario")
    fullname: str = Field(..., alias="nombre_completo",min_length=1)
    email: EmailStr = Field(..., alias="correo")
    role: str = Field(...,alias="rol" , min_length=1)
    password: str = Field(...,alias="contrasena" , min_length=6)
    class Config:
        allow_population_by_field_name = True  # Permite usar tanto el alias como el nombre en inglés