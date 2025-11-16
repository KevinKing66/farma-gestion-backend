from fastapi import APIRouter
from src.schemas.item_schema import ItemCreate
from src.controllers import item_controller

router = APIRouter(prefix="/items")

@router.get("/")
def get_all():
    return item_controller.get_all()

@router.get("/medicanteos")
def find_all_inventario_by_keyword_and_pagination(filter: str, page, elementsPerPages: int = 5):
    return item_controller.find_all_medicamento_by_keyword_and_pagination()

@router.get("/{id_item}")
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
