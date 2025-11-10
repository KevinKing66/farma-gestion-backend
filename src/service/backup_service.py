from typing import Any, Dict, List, cast
from src.config.database import get_connection
from src.schemas.backup_schema import (
    BackupCreate,
    BackupUpdate,
    BackupResponse
)


class BackupNoEncontradoError(Exception):
    pass


def create_backup(backup: BackupCreate) -> int:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_generar_backup(%s, %s, %s)",
                (backup.generado_por, backup.ruta_archivo, backup.nombre_archivo)
            )
            result = cursor.fetchone()
            return result["id_backup"]
    finally:
        conn.close()


def get_backup_by_id(id_backup: int) -> BackupResponse:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_obtener_backup(%s)", (id_backup,))
            result = cursor.fetchone()
            if not result:
                raise BackupNoEncontradoError("Backup no encontrado")
            return BackupResponse(**cast(Dict[str, Any], result))
    finally:
        conn.close()


def list_backups(desde: str = None, hasta: str = None, estado: str = None) -> List[BackupResponse]:
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_listar_backups(%s, %s, %s)", (desde, hasta, estado))
            result = cursor.fetchall()
            return [BackupResponse(**cast(Dict[str, Any], row)) for row in result]
    finally:
        conn.close()


def update_backup(id_backup: int, backup: BackupUpdate):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute(
                "CALL sp_actualizar_backup(%s, %s, %s)",
                (id_backup, backup.estado, backup.mensaje)
            )
            conn.commit()
    finally:
        conn.close()


def delete_backup(id_backup: int):
    conn = get_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            cursor.execute("CALL sp_eliminar_backup(%s)", (id_backup,))
            conn.commit()
    finally:
        conn.close()