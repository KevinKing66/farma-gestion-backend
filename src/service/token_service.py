from typing import Any, Dict, List, cast
from src.config.database import get_connection
from src.schemas.token_schema import (
    TokenCreate,
    TokenUpdate,
    TokenResponse
)


class TokenNoEncontradoError(Exception):
    pass


def create_token(data: TokenCreate) -> int:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_crear_token_recuperacion(%s, %s, %s)",
                (data.id_usuario, data.token, data.expiracion)
            )
            result = cursor.fetchone()
            return result["id_token"]
    finally:
        conn.close()


def get_token_by_id(id_token: int) -> TokenResponse:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_obtener_token_recuperacion(%s)", (id_token,))
            result = cursor.fetchone()
            if not result:
                raise TokenNoEncontradoError("Token no encontrado")
            return TokenResponse(**cast(Dict[str, Any], result))
    finally:
        conn.close()


def list_tokens() -> List[TokenResponse]:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_listar_tokens_recuperacion()")
            result = cursor.fetchall()
            return [TokenResponse(**cast(Dict[str, Any], row)) for row in result]
    finally:
        conn.close()


def update_token(id_token: int, data: TokenUpdate):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_actualizar_token_recuperacion(%s, %s)",
                (id_token, data.usado)
            )
            conn.commit()
    finally:
        conn.close()


def delete_token(id_token: int):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_eliminar_token_recuperacion(%s)", (id_token,))
            conn.commit()
    finally:
        conn.close()