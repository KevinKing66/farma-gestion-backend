from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class BackupCreate(BaseModel):
    nombre_archivo: str
    ruta_archivo: str
    generado_por: int


class BackupUpdate(BaseModel):
    estado: str  # 'EXITOSO' o 'ERROR'
    mensaje: Optional[str] = None


class BackupResponse(BaseModel):
    id_backup: int
    nombre_archivo: str
    ruta_archivo: str
    fecha_creacion: datetime
    generado_por: Optional[int]
    estado: str
    mensaje: Optional[str] = None