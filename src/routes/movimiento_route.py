from fastapi import APIRouter
from src.schemas.lote_schema import LoteCreate
from src.controllers import movimiento_controller
from src.models.movimiento_model import TransferenciaModel


router = APIRouter(prefix="/movimientos")

@router.get("/")
def get_all():
    return movimiento_controller.get_all()

@router.get("/lote/{id_lote}")
def get_by_lote(id_lote: int):
    return movimiento_controller.get_by_lote(id_lote)

@router.post("/crear-lote")
def crear_lote(data: LoteCreate):
    return movimiento_controller.crear_lote(data)

