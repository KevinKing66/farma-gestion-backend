from fastapi import APIRouter
from src.controllers import stg_inventario_controller

router = APIRouter(prefix="/stg_inventario")

@router.get("/")
def get_all():
    return stg_inventario_controller.get_all()

@router.post("/")
def create(data):
    return stg_inventario_controller.create(data)

@router.delete("/{lote}/{item}")
def delete_all(lote: str, item: str):
    return stg_inventario_controller.delete(item=item, lote=lote)
