from fastapi import APIRouter
from src.controllers import comprobante_controller

router = APIRouter(prefix="/comprobantes")

@router.get("/")
def get_all():
    return comprobante_controller.find_all()

@router.get("/proveedor/{proveedor}")
def find_all_by_proveedor(proveedor: int):
    return comprobante_controller.find_all_by_proveedor(proveedor)

@router.get("/{id_comprobante}")
def get_one(id_comprobante: int):
    return comprobante_controller.find_one(id_comprobante)

@router.post("/")
def create(data: dict):
    return comprobante_controller.create(data)

@router.put("/entregar/{id_comprobante}")
def marcar_entregado(id_comprobante: int):
    return comprobante_controller.marcar_entregado(id_comprobante)

@router.delete("/{id_comprobante}")
def delete(id_comprobante: int):
    return comprobante_controller.delete(id_comprobante)
