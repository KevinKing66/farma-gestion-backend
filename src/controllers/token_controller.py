from fastapi import HTTPException
from src.service.token_service import (
    create_token,
    get_token_by_id,
    list_tokens,
    update_token,
    delete_token,
    TokenNoEncontradoError
)
from src.schemas.token_schema import TokenCreate, TokenUpdate


def crear_token_controller(data: TokenCreate):
    try:
        return create_token(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def obtener_token_controller(id_token: int):
    try:
        return get_token_by_id(id_token)
    except TokenNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


def listar_tokens_controller():
    return list_tokens()


def actualizar_token_controller(id_token: int, data: TokenUpdate):
    try:
        update_token(id_token, data)
        return {"mensaje": "Token actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def eliminar_token_controller(id_token: int):
    try:
        delete_token(id_token)
        return {"mensaje": "Token eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))