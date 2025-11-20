from fastapi import APIRouter
from src.schemas.item_schema import ItemCreate
from src.controllers import item_controller

router = APIRouter(prefix="/items")

@router.get("/")
def find_all_with_pagination():
    return item_controller.get_all()

@router.get("/filtro")
def find_all_with_pagination(keyboard: str | None = "", page: int = 1, elementsPerPages: int = 10):
    return item_controller.find_all_by_keyword_and_pagination(filter=keyboard, pages=page, elementPerPages=elementsPerPages)


@router.get("/medicamentos")
def find_all_inventario_by_keyword_and_pagination(keyboard: str | None = "", page: int = 1, elementsPerPages: int = 10):
    return item_controller.find_all_medicamento_by_keyword_and_pagination(filter=keyboard, pages=page, elementPerPages=elementsPerPages)

@router.get("/id/{id_item}")
def get_one(id_item: int):
    return item_controller.get_one(id_item)

@router.post("/")
def create(data: ItemCreate):
    return item_controller.create(data)

@router.put("/{id_item}")
def update(id_item: int, data: dict):
    return item_controller.update(id_item, data)

@router.delete("/{id_item}")
def delete(id_item: int):
    return item_controller.delete(id_item)


@router.put("/change-location/{id}")
def change_location(id: int, data: dict):
    return item_controller.update_location(id, data)
