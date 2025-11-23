from fastapi import HTTPException
from src.schemas.orden_schema import (
    OrdenCreate,
    OrdenDetalleCreate,
    OrdenEstadoUpdate,
    OrdenDetalleUpdate
)
from src.service import orden_service


def find_all(filter, page, limit):
    return orden_service.find_all_with_pagination(filter, page, limit)


def find_all_v2(filter, estado, page, limit):
    return orden_service.find_all_with_pagination_v2(filter, estado, page, limit)


def create(data: OrdenCreate):
    return orden_service.crear_orden(data)


def add_detail(id_orden: int, data: OrdenDetalleCreate):
    return orden_service.add_details(id_orden, data)


def update_state(id_orden: int, data: OrdenEstadoUpdate):
    return orden_service.update_estado(id_orden, data.estado, data.id_usuario)


def get_detail(id_orden: int):
    result = orden_service.find_detail(id_orden)
    if not result:
        raise HTTPException(status_code=404, detail="No hay detalles para esta orden")
    return result


def update_detail(data: OrdenDetalleUpdate):
    return orden_service.update_details(data)


def delete(id_orden: int, id_usuario: int):
    return orden_service.delete(id_orden, id_usuario)


def update_last_attention_date(id_paciente):
    return orden_service.updateLastAttentionDate(id_paciente)