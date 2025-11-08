from fastapi import HTTPException
from src.service import parametro_service
from src.schemas.parametro_schema import (
    ParametroCreate,
    ParametroUpdate,
    ParametroResponse
)
from typing import List


def listar_parametros() -> List[ParametroResponse]:
    return parametro_service.get_all_parametros()


def obtener_parametro(clave: str) -> ParametroResponse | None:
    try:
        return parametro_service.get_parametro_by_pk(clave)
    except parametro_service.ParametroNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


def crear_parametro(parametro: ParametroCreate):
    try:
        parametro_service.create_parametro(parametro)
        return {"message": "Parámetro creado correctamente"}
    except parametro_service.ParametroExistenteError as e:
        raise HTTPException(status_code=400, detail=str(e))


def actualizar_parametro(clave: str, parametro: ParametroUpdate):
    try:
        parametro_service.update_parametro(clave, parametro)
        return {"message": "Parámetro actualizado correctamente"}
    except parametro_service.ParametroNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


def eliminar_parametro(clave: str):
    try:
        parametro_service.delete_parametro(clave)
        return {"message": "Parámetro eliminado correctamente"}
    except parametro_service.ParametroNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))
