from pydantic import BaseModel
from typing import Optional

class MovimientoBase(BaseModel):
    id_item: int
    id_lote: int
    id_usuario: int
    cantidad: float
    observacion: Optional[str] = None

class MovimientoCreate(MovimientoBase):
    pass
