from services import movimientos_service

def get_all():
    return movimientos_service.get_all()

def create(data):
    movimientos_service.insert_movimiento(
        data["id_lote"],
        data["id_usuario"],
        data["tipo"],
        data["cantidad"],
        data.get("id_ubicacion_origen"),
        data.get("id_ubicacion_destino"),
        data.get("motivo")
    )
    return {"message": "Movimiento registrado correctamente"}

def get_by_lote(id_lote: int):
    return movimientos_service.get_by_lote(id_lote)
