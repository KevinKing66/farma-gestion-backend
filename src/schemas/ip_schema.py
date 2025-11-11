from pydantic import BaseModel
from datetime import datetime


class IPCreate(BaseModel):
    ip: str
    descripcion: str
    id_usuario: int


class IPResponse(BaseModel):
    id_ip: int
    ip: str
    descripcion: str
    fecha_registro: datetime