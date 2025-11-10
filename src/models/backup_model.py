from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class Backup(BaseModel):
    id_backup: int
    nombre_archivo: str
    ruta_archivo: str
    fecha_creacion: datetime
    generado_por: Optional[int]
    estado: str
    mensaje: Optional[str] = None