from fastapi import HTTPException
from src.schemas.orden_schema import (
    OrdenCreate,
    OrdenDetalleCreate,
    OrdenEstadoUpdate,
    OrdenDetalleUpdate
)
from src.service import orden_service


def find_all(filter, page, limit):
    try:
        return orden_service.find_all_with_pagination(filter, page, limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def find_all_v2(filter, estado, page, limit):
    try:
        return orden_service.find_all_with_pagination_v2(filter, estado, page, limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def create(data: OrdenCreate):
    try:
        return orden_service.crear_orden(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def add_detail(id_orden: int, data: OrdenDetalleCreate):
    try:
        return orden_service.add_details(id_orden, data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def update_state(id_orden: int, data: OrdenEstadoUpdate):
    try:
        return orden_service.update_estado(id_orden, data.estado, data.id_usuario)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def get_detail(id_orden: int):
    try:
        result = orden_service.find_detail(id_orden)
        if not result:
            raise HTTPException(status_code=404, detail="No hay detalles para esta orden")
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def update_detail(data: OrdenDetalleUpdate):
    try:
        return orden_service.update_details(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def delete(id_orden: int, id_usuario: int):
    try:
        return orden_service.delete(id_orden, id_usuario)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def update_last_attention_date(id_paciente):
    try:
        return orden_service.updateLastAttentionDate(id_paciente)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))