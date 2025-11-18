from src.service import proveedor_service

def find_all():
    return proveedor_service.find_all_proveedores()

def find_all_with_pagination(filter: str = 0, pages: int = 0, elementPerPages: int = 10):
    return proveedor_service.find_all_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)

def find_one(id):
    return proveedor_service.find_by_id(id)

def create(data):
    return proveedor_service.create_proveedor(
        data["nombre"],
        data["nit"]
    )

def update(id_proveedor, data):
    proveedor_service.update_proveedor(
        id_proveedor,
        data["nombre"],
        data["nit"]
    )
    return {"message": "Proveedor actualizado correctamente"}

def delete(id_proveedor):
    proveedor_service.delete_proveedor(id_proveedor)
    return {"message": "Proveedor eliminado correctamente"}
