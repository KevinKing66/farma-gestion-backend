from fastapi import HTTPException
from src.schemas.lote_schema import AssignLotLocation, LoteCreate, LoteUpdate, LotePosicionResponse, SalidaSchema
from src.schemas.item_schema import ItemTranferir
from src.service import lote_service

def get_all():
    return lote_service.get_all_lotes()

def get_all_by_lote():
    return lote_service.get_all_lotes()

def find_all_with_pagination(filter, page, elementPerPages):
    return lote_service.find_all_with_pagination(filter, page, elementPerPages)

def get_one(id_lote):
    return lote_service.get_lote_by_id(id_lote)

def create(data: LoteCreate):
    return lote_service.create_lote(lote=data)

def update(id, data: LoteUpdate):
    lote_service.update_lote(
        id,
        data.fecha_vencimiento,
        data.costo_unitario
    )
    return {"message": "Lote actualizado correctamente"}

def delete(id_lote):
    lote_service.delete_lote(id_lote)
    return {"message": "Lote eliminado correctamente"}

def update_location(data: ItemTranferir):
    return lote_service.update_location(data)

def assign_location(data: AssignLotLocation):
    return lote_service.assign_location_ctx(
            data.id_lote,
            data.id_ubicacion,
            data.estante,
            data.nivel,
            data.pasillo,
            data.id_usuario
            )


def get_lote_posicion(id_pos: int):
    registro = lote_service.get_lote_posicion_by_id(id_pos)
    if not registro:
        raise HTTPException(status_code=404, detail="Posición de lote no encontrada")
    return LotePosicionResponse(**registro)

def registrar_ingreso(data):
    return lote_service.registrar_ingreso(data)


def registrar_salida(data: SalidaSchema):
    return lote_service.registrar_salida(data)
    

def transferir_stock(data):
    return lote_service.transferir_stock(data)
