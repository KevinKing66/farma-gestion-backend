from fastapi import APIRouter
from src.controllers import inventario_controller

router = APIRouter(prefix="/inventario")

@router.get("/")
def find_all():
    return inventario_controller.find_all()

@router.get("/filter")
def find_all_with_pagination(keyboard: str | None = "", page: int = 0, elementsPerPages: int = 5):
    return inventario_controller.find_all_inventario_by_keyword_and_pagination(filter=keyboard, page=page, elementPerPages=elementsPerPages)