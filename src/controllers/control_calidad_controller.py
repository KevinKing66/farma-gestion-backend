from fastapi import HTTPException
from src.service.control_calidad_service import (
    create_control_calidad,
    get_control_calidad_by_id,
    list_controles_by_lote,
    update_control_calidad,
    delete_control_calidad,
    ControlCalidadNoEncontradoError
)
from src.schemas.control_calidad_schema import ControlCalidadCreate, ControlCalidadUpdate


def crear_control_calidad_controller(data: ControlCalidadCreate):
    try:
        return create_control_calidad(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def obtener_control_calidad_controller(id_control: int):
    try:
        return get_control_calidad_by_id(id_control)
    except ControlCalidadNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


def listar_controles_por_lote_controller(id_lote: int):
    return list_controles_by_lote(id_lote)


def actualizar_control_calidad_controller(id_control: int, data: ControlCalidadUpdate):
    try:
        update_control_calidad(id_control, data)
        return {"mensaje": "Control actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def eliminar_control_calidad_controller(id_control: int):
    try:
        delete_control_calidad(id_control)
        return {"mensaje": "Control eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))