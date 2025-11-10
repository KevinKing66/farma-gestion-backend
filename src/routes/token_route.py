from fastapi import APIRouter
from src.schemas.token_schema import (
    TokenCreate,
    TokenUpdate,
    TokenResponse
)
from src.controllers.token_controller import (
    crear_token_controller,
    obtener_token_controller,
    listar_tokens_controller,
    actualizar_token_controller,
    eliminar_token_controller
)

router = APIRouter(prefix="/tokens", tags=["Tokens de Recuperación"])


@router.post("/", response_model=int)
def crear_token(data: TokenCreate):
    return crear_token_controller(data)


@router.get("/{id_token}", response_model=TokenResponse)
def obtener_token(id_token: int):
    return obtener_token_controller(id_token)


@router.get("/", response_model=list[TokenResponse])
def listar_tokens():
    return listar_tokens_controller()


@router.put("/{id_token}")
def actualizar_token(id_token: int, data: TokenUpdate):
    return actualizar_token_controller(id_token, data)


@router.delete("/{id_token}")
def eliminar_token(id_token: int):
    return eliminar_token_controller(id_token)