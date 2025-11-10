from fastapi import APIRouter, Depends
from src.schemas.backup_schema import BackupCreate, BackupUpdate, BackupResponse
from src.controllers.backup_controller import (
    crear_backup_controller,
    obtener_backup_controller,
    listar_backups_controller,
    actualizar_backup_controller,
    eliminar_backup_controller
)

router = APIRouter(prefix="/backups", tags=["Backups"])


@router.post("/", response_model=int)
def crear_backup(data: BackupCreate):
    return crear_backup_controller(data)


@router.get("/{id_backup}", response_model=BackupResponse)
def obtener_backup(id_backup: int):
    return obtener_backup_controller(id_backup)


@router.get("/", response_model=list[BackupResponse])
def listar_backups(desde: str = None, hasta: str = None, estado: str = None):
    return listar_backups_controller(desde, hasta, estado)


@router.put("/{id_backup}")
def actualizar_backup(id_backup: int, data: BackupUpdate):
    return actualizar_backup_controller(id_backup, data)


@router.delete("/{id_backup}")
def eliminar_backup(id_backup: int):
    return eliminar_backup_controller(id_backup)