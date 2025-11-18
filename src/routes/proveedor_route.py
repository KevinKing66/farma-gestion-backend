from fastapi import APIRouter
from src.controllers import proveedor_controller

router = APIRouter(prefix="/proveedores")

@router.get("/")
def find_all():
    return proveedor_controller.find_all()

@router.get("/id/{id_proveedor}")
def find_one(id: int):
    return proveedor_controller.find_one(id)

@router.post("/")
def create(data: dict):
    return proveedor_controller.create(data)

@router.put("/{id_proveedor}")
def update(id_proveedor: int, data: dict):
    return proveedor_controller.update(id_proveedor, data)

@router.delete("/{id_proveedor}")
def delete(id_proveedor: int):
    return proveedor_controller.delete(id_proveedor)
