from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TokenRecuperacion(BaseModel):
    id_token: int
    id_usuario: int
    token: str
    expiracion: datetime
    usado: Optional[int]