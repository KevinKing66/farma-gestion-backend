from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class RolEnum(str, Enum):
    AUXILIAR = "AUXILIAR"
    REGENTE = "REGENTE"
    AUDITOR = "AUDITOR"
    ADMIN = "ADMIN"
    PROVEEDOR = "PROVEEDOR"

class Usuario(BaseModel):
    id_usuario: Optional[int] = None
    nombre_completo: str = Field(..., max_length=150)
    correo: EmailStr
    rol: RolEnum
    contrasena: str
    intentos_fallidos: int = 0
    bloqueado_hasta: Optional[datetime] = None
    fecha_ultimo_login: Optional[datetime] = None
    activo: int = 1

    class Config:
        orm_mode = True
