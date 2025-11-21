from pydantic import BaseModel

class SalidaSchema(BaseModel):
    id_lote: int
    id_ubicacion_origen: int
    id_ubicacion_destino: int
    cantidad: int
    id_usuario: int
    motivo: str
