from fastapi import HTTPException
from src.service import proveedor_service

def find_all():
    try:
        return proveedor_service.find_all_proveedores()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def find_all_with_pagination(filter: str = "", pages: int = 1, elementPerPages: int = 10):
    return proveedor_service.find_all_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)

def find_one(id):
    try:
        return proveedor_service.find_by_id(id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data):
    try:
        return proveedor_service.create_proveedor(
            data["nombre"],
            data["nit"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update(id_proveedor, data):
    try:
        proveedor_service.update_proveedor(
            id_proveedor,
            data["nombre"],
            data["nit"]
        )
        return {"message": "Proveedor actualizado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete(id_proveedor):
    try:
        proveedor_service.delete_proveedor(id_proveedor)
        return {"message": "Proveedor eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
