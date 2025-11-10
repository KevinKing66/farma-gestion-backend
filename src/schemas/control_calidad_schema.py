from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ControlCalidadCreate(BaseModel):
    id_lote: int
    observaciones: Optional[str]
    resultado: str  # 'APROBADO' o 'RECHAZADO'
    evidencia: Optional[str]
    registrado_por: Optional[int]


class ControlCalidadUpdate(BaseModel):
    observaciones: Optional[str]
    resultado: str
    evidencia: Optional[str]


class ControlCalidadResponse(BaseModel):
    id_control: int
    id_lote: int
    fecha_control: datetime
    observaciones: Optional[str]
    resultado: str
    evidencia: Optional[str]
    registrado_por: Optional[int]
    auditor: Optional[str]