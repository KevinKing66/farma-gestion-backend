from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class IncidenteAlmacenamiento(BaseModel):
    id_incidente: int
    fecha: datetime
    descripcion: str
    responsable: str
    accion_correctiva: Optional[str]
    evidencia: Optional[str]
    registrado_por: Optional[int]
    registrado_por_nombre: Optional[str]