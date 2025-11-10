from fastapi import APIRouter
from src.schemas.incidente_schema import (
    IncidenteCreate,
    IncidenteUpdate,
    IncidenteResponse
)
from src.controllers.incidente_controller import (
    crear_incidente_controller,
    obtener_incidente_controller,
    listar_incidentes_controller,
    actualizar_incidente_controller,
    eliminar_incidente_controller
)

router = APIRouter(prefix="/incidentes", tags=["Incidentes de Almacenamiento"])


@router.post("/", response_model=int)
def crear_incidente(data: IncidenteCreate):
    return crear_incidente_controller(data)


@router.get("/{id_incidente}", response_model=IncidenteResponse)
def obtener_incidente(id_incidente: int):
    return obtener_incidente_controller(id_incidente)


@router.get("/", response_model=list[IncidenteResponse])
def listar_incidentes():
    return listar_incidentes_controller()


@router.put("/{id_incidente}")
def actualizar_incidente(id_incidente: int, data: IncidenteUpdate):
    return actualizar_incidente_controller(id_incidente, data)


@router.delete("/{id_incidente}")
def eliminar_incidente(id_incidente: int):
    return eliminar_incidente_controller(id_incidente)