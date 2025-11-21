from pydantic import BaseModel
from datetime import date

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