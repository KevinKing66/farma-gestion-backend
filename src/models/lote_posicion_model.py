from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class LotePosicion(BaseModel):
    id_posicion: int
    id_lote: int
    id_ubicacion: int
    estante: Optional[str]
    nivel: Optional[str]
    pasillo: Optional[str]
    fecha_asignacion: datetime
    asignado_por: Optional[int]
    ubicacion: Optional[str]  # nombre del almacén