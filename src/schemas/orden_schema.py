from pydantic import BaseModel
from typing import Optional, List


class OrdenCreate(BaseModel):
    id_paciente: int
    id_usuario: int
    observaciones: Optional[str] = None


class OrdenDetalleCreate(BaseModel):
    id_item: int
    cantidad: float
    id_usuario: int
    


class OrdenDetalleUpdate(BaseModel):
    id_detalle: int
    id_orden: Optional[int] = None
    id_item: Optional[int] = None
    cantidad: Optional[float] = None
    id_usuario: int

class OrdenResponse(BaseModel):
    id_orden: int
    paciente: str
    fecha: str
    estado: str

class OrdenEstadoUpdate(BaseModel):
    estado: str
    id_usuario: int


class OrdenDetalleResponse(BaseModel):
    medicamento: str
    cantidad: float
