from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TokenCreate(BaseModel):
    id_usuario: int
    token: str
    expiracion: datetime


class TokenUpdate(BaseModel):
    usado: int  # 0 o 1


class TokenResponse(BaseModel):
    id_token: int
    id_usuario: int
    token: str
    expiracion: datetime
    usado: Optional[int]