from fastapi import APIRouter
from src.controllers import inventario_controller

router = APIRouter(prefix="/inventario")

@router.get("/")
def listar_inventario():
    return inventario_controller.find_all()

@router.get("/filter")
def buscar_inventario(filter: str, page, elementsPerPages: int = 5):
    return inventario_controller.find_all_inventario_by_keyword_and_pagination(filter=filter, page=page, elementPerPages=elementsPerPages)