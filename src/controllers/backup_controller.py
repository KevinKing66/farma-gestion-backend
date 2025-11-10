from fastapi import HTTPException
from src.service.backup_service import (
    create_backup,
    get_backup_by_id,
    list_backups,
    update_backup,
    delete_backup,
    BackupNoEncontradoError
)
from src.schemas.backup_schema import BackupCreate, BackupUpdate


def crear_backup_controller(data: BackupCreate):
    try:
        return create_backup(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def obtener_backup_controller(id_backup: int):
    try:
        return get_backup_by_id(id_backup)
    except BackupNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


def listar_backups_controller(desde: str = None, hasta: str = None, estado: str = None):
    return list_backups(desde, hasta, estado)


def actualizar_backup_controller(id_backup: int, data: BackupUpdate):
    try:
        update_backup(id_backup, data)
        return {"mensaje": "Backup actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def eliminar_backup_controller(id_backup: int):
    try:
        delete_backup(id_backup)
        return {"mensaje": "Backup eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
