from fastapi import APIRouter
from src.schemas.orden_schema import (
    OrdenCreate,
    OrdenDetalleCreate,
    OrdenEstadoUpdate,
    OrdenDetalleUpdate
)
from src.controllers import orden_controller

router = APIRouter(prefix="/ordenes", tags=["Ordenes"])


@router.get("/")
def get_all(filtro: str = "", page: int = 1, limit: int = 10):
    return orden_controller.find_all(filtro, page, limit)


@router.get("/v2")
def get_all_v2(
    filtro: str = "",
    estado: str = "PENDIENTE",
    page: int = 1,
    limit: int = 10
):
    return orden_controller.find_all_v2(filtro, estado, page, limit)


@router.post("/")
def create(data: OrdenCreate):
    return orden_controller.create(data)


@router.post("/detalle/{id_orden}")
def add_detail(id_orden: int, data: OrdenDetalleCreate):
    return orden_controller.add_detail(id_orden, data)


@router.put("/estado/{id_orden}")
def update_state(id_orden: int, data: OrdenEstadoUpdate):
    return orden_controller.update_state(id_orden, data)



@router.put("/update_last_attention_date/{id_paciente}")
def update_last_attention_date(id_paciente: int):
    return orden_controller.update_last_attention_date(id_paciente)


@router.get("/detalle/id/{id_orden}")
def get_detail(id_orden: int):
    return orden_controller.get_detail(id_orden)


@router.put("/detalle")
def update_detail(data: OrdenDetalleUpdate):
    return orden_controller.update_detail(data)


@router.delete("/{id_orden}")
def delete(id_orden: int, id_usuario: int):
    return orden_controller.delete(id_orden, id_usuario)


