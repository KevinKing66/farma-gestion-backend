from fastapi import APIRouter
from src.schemas.item_schema import ItemTranferir
from src.schemas.lote_schema import AssignLotLocation, LoteCreate, LoteUpdate, IngresoSchema, SalidaSchema
from src.controllers import lote_controller

router = APIRouter(prefix="/lotes")

@router.get("/")
def get_all():
    return lote_controller.get_all()

@router.get("/filtro")
def find_all_with_pagination(keyword: str | None = "", page: int = 1, elementsPerPages: int = 10):
    return lote_controller.find_all_with_pagination(filter=keyword, page=page, elementPerPages=elementsPerPages)


@router.get("/id/{id_lote}")
def get_one(id_lote: int):
    return lote_controller.get_one(id_lote)

@router.post("/")
def create(data: LoteCreate):
    return lote_controller.create(data)

@router.put("/update/{id_lote}")
def update(id_lote: int, data: LoteUpdate):
    return lote_controller.update(id_lote, data)

@router.delete("/{id_lote}")
def delete(id_lote: int):
    return lote_controller.delete(id_lote)


@router.put("/change-location")
def change_location(data: ItemTranferir):
    return lote_controller.update_location(data)

@router.put("/assign-location")
def assign_location_ctx(data: AssignLotLocation):
    return lote_controller.update_location(data)

@router.get("/posicion/{id_pos}")
def get_lote_posicion(id_pos: int):
    return lote_controller.get_lote_posicion(id_pos)

@router.post("/registrar-ingreso")
def registrar_ingreso(data: IngresoSchema):
    return lote_controller.registrar_ingreso(data)

@router.post("/transferir")
def transferir_stock(data: ItemTranferir):
    return lote_controller.transferir_stock(data)

@router.post("/ingreso")
def registrar_ingreso(data: IngresoSchema):
    return lote_controller.registrar_ingreso(data)

@router.post("/salida")
def registrar_salida(data: SalidaSchema):
    return lote_controller.registrar_salida(data)