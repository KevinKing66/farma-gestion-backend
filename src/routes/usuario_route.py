from fastapi import APIRouter
from controllers import usuario_controller

router = APIRouter(prefix="/usuarios")

@router.get("/")
def get_all():
    return usuario_controller.get_all()

@router.get("/{id_usuario}")
def get_one(id_usuario: int):
    return usuario_controller.get_one(id_usuario)

@router.post("/")
def create(data: dict):
    return usuario_controller.create(data)

@router.put("/{id_usuario}")
def update(id_usuario: int, data: dict):
    return usuario_controller.update(id_usuario, data)

@router.delete("/{id_usuario}")
def delete(id_usuario: int):
    return usuario_controller.delete(id_usuario)
