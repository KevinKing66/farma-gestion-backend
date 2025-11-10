from fastapi import APIRouter
from src.schemas.control_calidad_schema import (
    ControlCalidadCreate,
    ControlCalidadUpdate,
    ControlCalidadResponse
)
from src.controllers.control_calidad_controller import (
    crear_control_calidad_controller,
    obtener_control_calidad_controller,
    listar_controles_por_lote_controller,
    actualizar_control_calidad_controller,
    eliminar_control_calidad_controller
)

router = APIRouter(prefix="/control-calidad", tags=["Control de Calidad"])


@router.post("/", response_model=int)
def crear_control(data: ControlCalidadCreate):
    return crear_control_calidad_controller(data)


@router.get("/{id_control}", response_model=ControlCalidadResponse)
def obtener_control(id_control: int):
    return obtener_control_calidad_controller(id_control)


@router.get("/por-lote/{id_lote}", response_model=list[ControlCalidadResponse])
def listar_controles_por_lote(id_lote: int):
    return listar_controles_por_lote_controller(id_lote)


@router.put("/{id_control}")
def actualizar_control(id_control: int, data: ControlCalidadUpdate):
    return actualizar_control_calidad_controller(id_control, data)


@router.delete("/{id_control}")
def eliminar_control(id_control: int):
    return eliminar_control_calidad_controller(id_control)