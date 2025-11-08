from fastapi import APIRouter
from src.controllers import parametro_controller
from src.schemas.parametro_schema import (
    ParametroCreate,
    ParametroUpdate,
    ParametroResponse
)
from typing import List

router = APIRouter(prefix="/parametros", tags=["Parámetros del Sistema"])


@router.get("/", response_model=List[ParametroResponse])
def listar_parametros():
    return parametro_controller.listar_parametros()


@router.get("/{clave}", response_model=ParametroResponse)
def obtener_parametro(clave: str):
    return parametro_controller.obtener_parametro(clave)


@router.post("/")
def crear_parametro(parametro: ParametroCreate):
    return parametro_controller.crear_parametro(parametro)


@router.put("/{clave}")
def actualizar_parametro(clave: str, parametro: ParametroUpdate):
    return parametro_controller.actualizar_parametro(clave, parametro)


@router.delete("/{clave}")
def eliminar_parametro(clave: str):
    return parametro_controller.eliminar_parametro(clave)
