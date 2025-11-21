# src/schemas/exportar_inventario_schema.py
from pydantic import BaseModel

class ExportarInventarioResponseSchema(BaseModel):
    nombre: str
    lote: str
    categoria: str
    stock: int
    fecha_vencimiento: str | None
    ubicacion: str | None

    model_config = {
        "from_attributes": True
    }
