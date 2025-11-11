from pydantic import BaseModel, Field
from typing import Literal, Optional

class ItemBase(BaseModel):
    id_ubicacion: int
    descripcion: str = Field(..., max_length=255)
    tipo_item: Literal["MEDICAMENTO", "DISPOSITIVO"]
    unidad_medida: str = "UND"
    stock_minimo: int = 0

class ItemCreate(BaseModel):
    id_ubicacion: int = Field(..., description="ID de la ubicación asociada al item")
    codigo: str = Field(..., max_length=50, description="Código único del item (puede ser nulo)")
    descripcion: str = Field(..., max_length=255, description="Descripción del item")
    tipo_item: Literal["MEDICAMENTO", "DISPOSITIVO"] = Field(..., description="Tipo de item")
    unidad_medida: Optional[str] = Field("UND", max_length=20, description="Unidad de medida del item")
    stock_minimo: Optional[int] = Field(0, ge=0, description="Cantidad mínima en stock antes de alerta")

class ItemUpdate(ItemBase):
    pass

class ItemResponse(ItemBase):
    codigo: str
    id_item: int
    nombre_ubicacion: str

    class Config:
        orm_mode = True
