from pydantic import BaseModel
from datetime import datetime


class IP(BaseModel):
    id_ip: int
    ip: str
    descripcion: str
    fecha_registro: datetime