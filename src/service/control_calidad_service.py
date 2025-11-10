from typing import Any, Dict, List, cast
from src.config.database import get_connection
from src.schemas.control_calidad_schema import (
    ControlCalidadCreate,
    ControlCalidadUpdate,
    ControlCalidadResponse
)


class ControlCalidadNoEncontradoError(Exception):
    pass


def create_control_calidad(data: ControlCalidadCreate) -> int:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_crear_control_calidad(%s, %s, %s, %s)",
                (
                    data.id_lote,
                    data.observaciones,
                    data.resultado,
                    data.evidencia
                )
            )
            result = cursor.fetchone()
            return result["id_control"]
    finally:
        conn.close()


def get_control_calidad_by_id(id_control: int) -> ControlCalidadResponse:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_obtener_control_calidad(%s)", (id_control,))
            result = cursor.fetchone()
            if not result:
                raise ControlCalidadNoEncontradoError("Control de calidad no encontrado")
            return ControlCalidadResponse(**cast(Dict[str, Any], result))
    finally:
        conn.close()


def list_controles_by_lote(id_lote: int) -> List[ControlCalidadResponse]:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_listar_controles_calidad(%s)", (id_lote,))
            result = cursor.fetchall()
            return [ControlCalidadResponse(**cast(Dict[str, Any], row)) for row in result]
    finally:
        conn.close()


def update_control_calidad(id_control: int, data: ControlCalidadUpdate):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_actualizar_control_calidad(%s, %s, %s, %s)",
                (
                    id_control,
                    data.observaciones,
                    data.resultado,
                    data.evidencia
                )
            )
            conn.commit()
    finally:
        conn.close()


def delete_control_calidad(id_control: int):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_eliminar_control_calidad(%s)", (id_control,))
            conn.commit()
    finally:
        conn.close()