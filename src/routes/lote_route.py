from fastapi import APIRouter
from src.controllers import lote_controller

router = APIRouter(prefix="/lotes")

@router.get("/")
def get_all():
    return lote_controller.get_all()

@router.get("/{id_lote}")
def get_one(id_lote: int):
    return lote_controller.get_one(id_lote)

@router.post("/")
def create(data: dict):
    return lote_controller.create(data)

@router.put("/{id_lote}")
def update(id_lote: int, data: dict):
    return lote_controller.update(id_lote, data)

@router.delete("/{id_lote}")
def delete(id_lote: int):
    return lote_controller.delete(id_lote)
