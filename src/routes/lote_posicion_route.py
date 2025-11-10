from fastapi import APIRouter
from src.schemas.lote_posicion_schema import (
    LotePosicionCreate,
    LotePosicionUpdate,
    LotePosicionResponse
)
from src.controllers.lote_posicion_controller import (
    crear_lote_posicion_controller,
    obtener_lote_posicion_controller,
    listar_posiciones_por_lote_controller,
    actualizar_lote_posicion_controller,
    eliminar_lote_posicion_controller
)

router = APIRouter(prefix="/lote-posiciones", tags=["Lote Posiciones"])


@router.post("/", response_model=int)
def crear_posicion(data: LotePosicionCreate):
    return crear_lote_posicion_controller(data)


@router.get("/{id_posicion}", response_model=LotePosicionResponse)
def obtener_posicion(id_posicion: int):
    return obtener_lote_posicion_controller(id_posicion)


@router.get("/por-lote/{id_lote}", response_model=list[LotePosicionResponse])
def listar_posiciones_por_lote(id_lote: int):
    return listar_posiciones_por_lote_controller(id_lote)


@router.put("/{id_posicion}")
def actualizar_posicion(id_posicion: int, data: LotePosicionUpdate):
    return actualizar_lote_posicion_controller(id_posicion, data)


@router.delete("/{id_posicion}")
def eliminar_posicion(id_posicion: int):
    return eliminar_lote_posicion_controller(id_posicion)