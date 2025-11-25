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

class LoteUpdate(BaseModel):
    codigo_lote: Optional[str] = None
    fecha_vencimiento: Optional[date] = None
    costo_unitario: Optional[float] = None
    estado: Optional[str] = None 
    id_item: Optional[int] = None
    id_proveedor: Optional[int] = None
    cantidad: Optional[int] = None
    id_ubicacion: Optional[int] = None
    id_usuario: int
    motivo: Optional[str] = None


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
        
        

class IngresoSchema(BaseModel):
    id_item: int
    id_proveedor: int
    codigo_lote: str
    fecha_venc: date
    costo_unitario: float
    id_ubicacion_destino: int
    cantidad: int
    id_usuario: int
    motivo: str | None = None
    
    
class SalidaSchema(BaseModel):
    id_lote: int
    id_ubicacion_origen: int
    id_ubicacion_destino: int
    cantidad: int
    id_usuario: int
    motivo: str


class AssignLotLocation(BaseModel):
    id_lote: int
    id_ubicacion: int
    estante: Optional[str] = None
    nivel: Optional[str] = None
    pasillo: Optional[str] = None
    id_usuario: int