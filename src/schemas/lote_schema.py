from pydantic import BaseModel, Field
from datetime import date

class LoteBase(BaseModel):
    id_item: int
    id_proveedor: int
    codigo_lote: str = Field(..., max_length=50)
    fecha_vencimiento: date
    costo_unitario: float

class LoteCreate(LoteBase):
    pass

class LoteUpdate(LoteBase):
    id_item: int
    fecha_vencimiento: date
    costo_unitario: float

class LoteResponse(LoteBase):
    id_lote: int

    class Config:
        orm_mode = True
