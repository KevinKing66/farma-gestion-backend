from fastapi import HTTPException
from src.schemas.item_schema import ItemCreate, ItemTranferir
from src.service import item_service

def get_all():
    try:
        return item_service.get_all_items()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_one(id_item):
    try:
        return item_service.get_item_by_id(id_item)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data: ItemCreate):
    try:
        return item_service.create_item(
            data.id_ubicacion,
            data.codigo,
            data.descripcion,
            data.tipo_item or "MEDICAMENTO",
            data.unidad_medida or "UND",
            data.stock_minimo or 0
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update(id_item, data):
    try:
        item_service.update_item(
            id_item,
            data.get("id_ubicacion", None),
            data.get("codigo", None),
            data["descripcion"],
            data["tipo_item"],
            data.get("unidad_medida", "UND"),
            data.get("stock_minimo", 0)
        )
        return {"message": "Item actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update_location(data: ItemTranferir):
    try:
        return item_service.update_location(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete(id_item):
    try:
        item_service.delete_item(id_item)
        return {"message": "Item eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def find_all_medicamento_by_keyword_and_pagination(filter: str = "", pages: int = 1, elementPerPages: int = 10):
    try:
        return item_service.find_all_medicamento_by_keyword_and_pagination(keyword=filter, page=pages, elementPerPages=elementPerPages)
    except Exception as e:
        return {"error": str(e)}


def find_all_by_keyword_and_pagination(filter: str = 0, pages: int = 0, elementPerPages: int = 10):
    try:
        return item_service.find_all_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)
    except Exception as e:
        return {"error": str(e)}
