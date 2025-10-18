from src.service import ubicacion_service

def get_all():
    return ubicacion_service.get_all_ubicaciones()

def get_one(id_ubicacion):
    return ubicacion_service.get_ubicacion_by_id(id_ubicacion)

def create(data):
    print("------------entraaaaaaaaaaaaaaaaaaa")
    ubicacion_service.create_ubicacion(
        data["nombre"],
        data.get("tipo", "ALMACEN"),
        data.get("activo", 1)
    )
    return {"message": "Ubicación creada correctamente"}

def update(id_ubicacion, data):
    ubicacion_service.update_ubicacion(
        id_ubicacion,
        data["nombre"],
        data.get("tipo", "ALMACEN"),
        data.get("activo", 1)
    )
    return {"message": "Ubicación actualizada correctamente"}

def delete(id_ubicacion):
    ubicacion_service.delete_ubicacion(id_ubicacion)
    return {"message": "Ubicación eliminada correctamente"}
