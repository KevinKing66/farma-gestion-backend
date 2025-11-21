from fastapi import APIRouter
from src.controllers import movimiento_controller
from src.schemas.ingreso_schema import IngresoSchema
from src.schemas.salida_schema import SalidaSchema
from src.schemas.crear_lote_schema import CrearLoteSchema
from src.schemas.registrar_ingreso_schema import RegistrarIngresoSchema
from src.models.movimiento_model import TransferenciaModel


router = APIRouter(prefix="/movimientos")

@router.get("/")
def get_all():
    return movimiento_controller.get_all()

@router.get("/lote/{id_lote}")
def get_by_lote(id_lote: int):
    return movimiento_controller.get_by_lote(id_lote)

@router.post("/ingreso")
def registrar_ingreso(data: IngresoSchema):
    return movimiento_controller.registrar_ingreso(data)

@router.post("/salida")
def registrar_salida(data: SalidaSchema):
    return movimiento_controller.registrar_salida(data)

@router.post("/crear-lote")
def crear_lote(data: CrearLoteSchema):
    return movimiento_controller.crear_lote(data)

@router.post("/registrar-ingreso")
def registrar_ingreso(data: RegistrarIngresoSchema):
    return movimiento_controller.registrar_ingreso(data)

@router.post("/transferir")
def transferir_stock(data: TransferenciaModel):
    return movimiento_controller.transferir_stock(data)
