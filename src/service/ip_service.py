from typing import Any, Dict, List, cast
from src.config.database import get_connection
from src.schemas.ip_schema import IPCreate, IPResponse


class IPNoEncontradaError(Exception):
    pass


def create_ip(data: IPCreate) -> int:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("SET @u_admin = %s", (data.id_usuario,))
            
            cursor.execute(
                "CALL sp_crear_ip(%s, %s, @u_admin)",
                (data.ip, data.descripcion)
            )
            conn.commit()
            return cursor.lastrowid
    finally:
        conn.close()



def get_ip_by_id(id_ip: int) -> IPResponse:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("SELECT * FROM ips_permitidas WHERE id_ip = %s", (id_ip,))
            result = cursor.fetchone()
            if not result:
                raise IPNoEncontradaError("IP no encontrada")
            return IPResponse(**cast(Dict[str, Any], result))
    finally:
        conn.close()


def list_ips() -> List[IPResponse]:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_listar_ips()")
            result = cursor.fetchall()
            return [IPResponse(**cast(Dict[str, Any], row)) for row in result]
    finally:
        conn.close()


def delete_ip(id_ip: int, id_usuario: int):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_eliminar_ip(%s, %s)", (id_ip, id_usuario))
            conn.commit()
    finally:
        conn.close()