from fastapi import HTTPException
from src.service.incidente_service import (
    create_incidente,
    get_incidente_by_id,
    list_incidentes,
    update_incidente,
    delete_incidente,
    IncidenteNoEncontradoError
)
from src.schemas.incidente_schema import IncidenteCreate, IncidenteUpdate


def crear_incidente_controller(data: IncidenteCreate):
    try:
        return create_incidente(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def obtener_incidente_controller(id_incidente: int):
    try:
        return get_incidente_by_id(id_incidente)
    except IncidenteNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


def listar_incidentes_controller():
    return list_incidentes()


def actualizar_incidente_controller(id_incidente: int, data: IncidenteUpdate):
    try:
        update_incidente(id_incidente, data)
        return {"mensaje": "Incidente actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def eliminar_incidente_controller(id_incidente: int):
    try:
        delete_incidente(id_incidente)
        return {"mensaje": "Incidente eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))