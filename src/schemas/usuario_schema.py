from pydantic import BaseModel, EmailStr, Field
from typing import Literal, Optional

class UsuarioBase(BaseModel):
    nombre_completo: str = Field(..., max_length=150)
    correo: EmailStr
    rol: Literal["AUXILIAR", "REGENTE", "AUDITOR", "ADMIN"]

class UsuarioCreate(UsuarioBase):
    contrasena: str = Field(..., max_length=255)

class UsuarioUpdate(BaseModel):
    nombre_completo: Optional[str]
    correo: Optional[EmailStr]
    rol: Optional[Literal["AUXILIAR", "REGENTE", "AUDITOR", "ADMIN"]]
    contrasena: Optional[str]

class UsuarioResponse(UsuarioBase):
    id_usuario: int
    intentos_fallidos: int
    bloqueado_hasta: Optional[str]

    class Config:
        orm_mode = True
