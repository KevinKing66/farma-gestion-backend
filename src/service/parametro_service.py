from typing import Any, Dict, cast, List
from src.config.database import get_connection
from src.schemas.parametro_schema import (
    ParametroCreate,
    ParametroUpdate,
    ParametroResponse
)


class ParametroExistenteError(Exception):
    pass


class ParametroNoEncontradoError(Exception):
    pass


def get_all_parametros() -> List[ParametroResponse]:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_listar_parametros()")
            result = cursor.fetchall()
            return [ParametroResponse(**cast(Dict[str, Any], row)) for row in result]
    finally:
        conn.close()


def get_parametro_by_pk(clave: str) -> ParametroResponse | None:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_obtener_parametro(%s)", (clave,))
            result = cursor.fetchone()
            if not result:
                raise ParametroNoEncontradoError("Parámetro no encontrado")
            return ParametroResponse(**cast(Dict[str, Any], result)) if result else None
    finally:
        conn.close()


def create_parametro(parametro: ParametroCreate):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("SELECT clave FROM parametros_sistema WHERE clave = %s", (parametro.clave,))
            if cursor.fetchone():
                raise ParametroExistenteError("Ya existe un parámetro con esa clave")

            cursor.execute(
                "CALL sp_crear_parametro(%s, %s, %s)",
                (parametro.clave, parametro.valor, parametro.descripcion)
            )
            conn.commit()
    finally:
        conn.close()


def update_parametro(clave: str, parametro: ParametroUpdate):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_actualizar_parametro(%s, %s, %s)",
                           (clave, parametro.valor, parametro.descripcion))
            conn.commit()
    finally:
        conn.close()


def delete_parametro(clave: str):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_eliminar_parametro(%s)", (clave,))
            conn.commit()
    finally:
        conn.close()
