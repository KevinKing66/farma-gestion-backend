from typing import Any, Dict, List, cast
from src.config.database import get_connection
from src.schemas.incidente_schema import (
    IncidenteCreate,
    IncidenteUpdate,
    IncidenteResponse
)


class IncidenteNoEncontradoError(Exception):
    pass


def create_incidente(data: IncidenteCreate) -> int:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_crear_incidente_almacenamiento(%s, %s, %s, %s)",
                (
                    data.descripcion,
                    data.responsable,
                    data.accion_correctiva,
                    data.evidencia
                )
            )
            result = cursor.fetchone()
            return result["id_incidente"] # type: ignore
    finally:
        conn.close()


def get_incidente_by_id(id_incidente: int) -> IncidenteResponse:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_obtener_incidente_almacenamiento(%s)", (id_incidente,))
            result = cursor.fetchone()
            if not result:
                raise IncidenteNoEncontradoError("Incidente no encontrado")
            return IncidenteResponse(**cast(Dict[str, Any], result))
    finally:
        conn.close()


def list_incidentes() -> List[IncidenteResponse]:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_listar_incidentes()")
            result = cursor.fetchall()
            return [IncidenteResponse(**cast(Dict[str, Any], row)) for row in result]
    finally:
        conn.close()


def update_incidente(id_incidente: int, data: IncidenteUpdate):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_actualizar_incidente_almacenamiento(%s, %s, %s, %s, %s)",
                (
                    id_incidente,
                    data.descripcion,
                    data.responsable,
                    data.accion_correctiva,
                    data.evidencia
                )
            )
            conn.commit()
    finally:
        conn.close()


def delete_incidente(id_incidente: int):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_eliminar_incidente(%s, %s)", (id_incidente, 1))  # ID usuario fijo
            conn.commit()
    finally:
        conn.close()