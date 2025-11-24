from fastapi import HTTPException
from src.schemas.lote_schema import AssignLotLocation, LoteCreate, LoteUpdate, LotePosicionResponse, SalidaSchema
from src.schemas.item_schema import ItemTranferir
from src.service import lote_service

def get_all():
    try:
        return lote_service.get_all_lotes()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_all_by_lote():
    try:
        return lote_service.get_all_lotes()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def find_all_with_pagination(filter, page, elementPerPages):
    try:
        return lote_service.find_all_with_pagination(filter, page, elementPerPages)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_one(id_lote):
    try:
        return lote_service.get_lote_by_id(id_lote)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data: LoteCreate):
    try:
        return lote_service.create_lote(lote=data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update(id, data: LoteUpdate):
    try:
        lote_service.update_lote(
            id,
            data.fecha_vencimiento,
            data.costo_unitario
        )
        return {"message": "Lote actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete(id_lote):
    try:
        lote_service.delete_lote(id_lote)
        return {"message": "Lote eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update_location(data: ItemTranferir):
    try:
        return lote_service.update_location(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def assign_location(data: AssignLotLocation):
    try:
        return lote_service.assign_location_ctx(
                data.id_lote,
                data.id_ubicacion,
                data.estante,
                data.nivel,
                data.pasillo,
                data.id_usuario
                )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def get_lote_posicion(id_pos: int):
    try:
        registro = lote_service.get_lote_posicion_by_id(id_pos)
        if not registro:
            raise HTTPException(status_code=404, detail="Posición de lote no encontrada")
        return LotePosicionResponse(**registro)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def registrar_ingreso(data):
    try:
        return lote_service.registrar_ingreso(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def registrar_salida(data: SalidaSchema):
    try:
        return lote_service.registrar_salida(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

def transferir_stock(data):
    try:
        return lote_service.transferir_stock(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))