from typing import Optional
from pydantic import BaseModel


class StgInventarioInicialSchema(BaseModel):
    codigo_item: str
    nit_proveedor: str
    codigo_lote: str
    fecha_vencimiento: str
    costo_unitario: float
    nombre_ubicacion: str
    cantidad: int


class StgInventarioInicialResponse(StgInventarioInicialSchema):
    id: Optional[int] = None