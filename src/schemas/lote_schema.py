from typing import Optional
from pydantic import BaseModel, Field
from datetime import date

class LoteBase(BaseModel):
    id_item: int
    id_proveedor: int
    codigo_lote: str = Field(..., max_length=50)
    fecha_vencimiento: date
    costo_unitario: float


class LoteCreate(BaseModel):
    id_item: Optional[int] = None
    nombre_item: Optional[str] = Field(None, max_length=255)
    unidad_medida: Optional[str] = Field(None, max_length=20)
    stock_minimo: Optional[int] = None
    id_proveedor: int
    codigo_lote: str = Field(..., max_length=50)
    fecha_vencimiento: date
    costo_unitario: float
    id_ubicacion_destino: int
    cantidad: int
    id_usuario: int
    motivo: Optional[str] = Field(None, max_length=255)
class LoteUpdate(LoteBase):
    id_item: int
    fecha_vencimiento: date
    costo_unitario: float

class LoteResponse(LoteBase):
    id_lote: int

    class Config:
        orm_mode = True


class LotePosicionBase(BaseModel):
    id_lote: int
    almacen: str = Field(..., max_length=50)
    estante: str = Field(..., max_length=50)
    nivel: Optional[str] = Field(None, max_length=20)
    pasillo: Optional[str] = Field(None, max_length=20)

class LotePosicionResponse(LotePosicionBase):
    id_posicion: int

    class Config:
        orm_mode = True