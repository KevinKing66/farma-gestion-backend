from fastapi import APIRouter
from src.schemas.ip_schema import IPCreate, IPResponse
from src.controllers.ip_controller import (
    crear_ip_controller,
    obtener_ip_controller,
    listar_ips_controller,
    eliminar_ip_controller
)

router = APIRouter(prefix="/ips", tags=["IPs Permitidas"])


@router.post("/", response_model=int)
def crear_ip(data: IPCreate):
    return crear_ip_controller(data)


@router.get("/{id_ip}", response_model=IPResponse)
def obtener_ip(id_ip: int):
    return obtener_ip_controller(id_ip)


@router.get("/", response_model=list[IPResponse])
def listar_ips():
    return listar_ips_controller()


@router.delete("/{id_ip}")
def eliminar_ip(id_ip: int, id_usuario: int):
    return eliminar_ip_controller(id_ip, id_usuario)