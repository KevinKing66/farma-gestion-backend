from pydantic import BaseModel

class Movimiento:
    def __init__(
        self,
        id_lote,
        id_usuario,
        tipo,
        cantidad,
        id_ubicacion_origen=None,
        id_ubicacion_destino=None,
        motivo=None
    ):
        self.id_lote = id_lote
        self.id_usuario = id_usuario
        self.tipo = tipo
        self.cantidad = cantidad
        self.id_ubicacion_origen = id_ubicacion_origen
        self.id_ubicacion_destino = id_ubicacion_destino
        self.motivo = motivo
        

class TransferenciaModel(BaseModel):
    id_lote: int
    id_ubicacion_origen: int
    id_ubicacion_destino: int
    cantidad: int
    id_usuario: int
    motivo: str

