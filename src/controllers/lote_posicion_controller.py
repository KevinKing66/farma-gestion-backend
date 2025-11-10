from fastapi import HTTPException
from src.service.lote_posicion_service import lote_service
from src.schemas.lote_posicion_schema import LotePosicionCreate, LotePosicionUpdate


def crear_lote_posicion_controller(data: LotePosicionCreate):
    try:
        return lote_service.create_lote_posicion(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def obtener_lote_posicion_controller(id_posicion: int):
    try:
        return lote_service.get_lote_posicion_by_id(id_posicion)
    except lote_service.LotePosicionNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))


def listar_posiciones_por_lote_controller(id_lote: int):
    return lote_service.list_lote_posiciones_by_lote(id_lote)


def actualizar_lote_posicion_controller(id_posicion: int, data: LotePosicionUpdate):
    try:
        lote_service.update_lote_posicion(id_posicion, data)
        return {"mensaje": "Posición actualizada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def eliminar_lote_posicion_controller(id_posicion: int):
    try:
        lote_service.delete_lote_posicion(id_posicion)
        return {"mensaje": "Posición eliminada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))