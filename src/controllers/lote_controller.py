from src.service import lote_service

def get_all():
    return lote_service.get_all_lotes()

def get_one(id_lote):
    return lote_service.get_lote_by_id(id_lote)

def create(data):
    lote_service.create_lote(
        data["id_item"],
        data["id_proveedor"],
        data["codigo_lote"],
        data["fecha_vencimiento"],
        data["costo_unitario"]
    )
    return {"message": "Lote creado correctamente"}

def update(id_lote, data):
    lote_service.update_lote(
        id_lote,
        data["id_item"],
        data["id_proveedor"],
        data["codigo_lote"],
        data["fecha_vencimiento"],
        data["costo_unitario"]
    )
    return {"message": "Lote actualizado correctamente"}

def delete(id_lote):
    lote_service.delete_lote(id_lote)
    return {"message": "Lote eliminado correctamente"}
