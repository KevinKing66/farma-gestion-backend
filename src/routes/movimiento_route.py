from fastapi import APIRouter
from controllers import movimientos_controller

router = APIRouter(prefix="/movimientos")

@router.get("/")
def get_all():
    return movimientos_controller.get_all()

@router.get("/lote/{id_lote}")
def get_by_lote(id_lote: int):
    return movimientos_controller.get_by_lote(id_lote)

@router.post("/")
def create(data: dict):
    return movimientos_controller.create(data)
