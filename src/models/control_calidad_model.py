from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ControlCalidad(BaseModel):
    id_control: int
    id_lote: int
    fecha_control: datetime
    observaciones: Optional[str]
    resultado: str
    evidencia: Optional[str]
    registrado_por: Optional[int]
    auditor: Optional[str]