from pydantic import BaseModel
from typing import Optional, Literal

class MovimientoBase(BaseModel):
    id_lote: int
    id_usuario: int
    tipo: Literal["INGRESO", "SALIDA", "TRANSFERENCIA", "AJUSTE"]
    cantidad: int
    id_ubicacion_origen: Optional[int] = None
    id_ubicacion_destino: Optional[int] = None
    motivo: Optional[str] = None

class MovimientoCreate(MovimientoBase):
    pass

class MovimientoResponse(MovimientoBase):
    id_movimiento: int
    fecha: str

    class Config:
        orm_mode = True

class InventarioFiltro(BaseModel):
    filtro: str = ""
    page: int = 1
    limit: int = 10


class StockAdjust(BaseModel):
    id_lote: int
    id_ubicacion: int
    cantidad: int
    sentido: str          # 'AUMENTO' | 'DISMINUCION'
    id_usuario: int
    motivo: Optional[str] = None
