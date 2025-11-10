from fastapi import HTTPException
from src.service.ip_service import (
    create_ip,
    get_ip_by_id,
    list_ips,
    delete_ip,
    IPNoEncontradaError
)
from src.schemas.ip_schema import IPCreate


def crear_ip_controller(data: IPCreate):
    try:
        return create_ip(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def obtener_ip_controller(id_ip: int):
    try:
        return get_ip_by_id(id_ip)
    except IPNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))


def listar_ips_controller():
    return list_ips()


def eliminar_ip_controller(id_ip: int, id_usuario: int):
    try:
        delete_ip(id_ip, id_usuario)
        return {"mensaje": "IP eliminada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))