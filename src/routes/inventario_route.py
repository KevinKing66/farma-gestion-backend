from fastapi import APIRouter
from src.controllers import inventario_controller
from src.schemas.inventario_schema import StockAdjust

router = APIRouter(prefix="/inventario")

@router.get("/")
def find_all():
    return inventario_controller.find_all()

@router.get("/filter")
def find_all_with_pagination(keyboard: str | None = "", page: int = 1, elementsPerPages: int = 10):
    return inventario_controller.find_all_inventario_by_keyword_and_pagination(filter=keyboard, page=page, elementPerPages=elementsPerPages)

@router.get("/medicamentos")
def find_all_inventario_by_keyword_and_pagination(keyboard: str | None = "", page: int = 1, elementsPerPages: int = 10):
    return inventario_controller.find_all_medicamento_by_keyword_and_pagination(keyword=keyboard, page=page, elementPerPages=elementsPerPages)

@router.get("/exportar")
def exportar_inventario():
    return inventario_controller.exportar_inventario()


@router.post("/stock_adjust")
def stock_adjust(data: StockAdjust):
    return inventario_controller.stock_adjust(data)