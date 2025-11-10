from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class LotePosicionCreate(BaseModel):
    id_lote: int
    id_ubicacion: int
    estante: str
    nivel: str
    pasillo: str
    asignado_por: Optional[int]


class LotePosicionUpdate(BaseModel):
    id_ubicacion: int
    estante: str
    nivel: str
    pasillo: str


class LotePosicionResponse(BaseModel):
    id_posicion: int
    id_lote: int
    id_ubicacion: int
    estante: Optional[str]
    nivel: Optional[str]
    pasillo: Optional[str]
    fecha_asignacion: datetime
    asignado_por: Optional[int]
    ubicacion: Optional[str]