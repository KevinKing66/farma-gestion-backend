from src.schemas.stg_inventario_inicial_schema import StgInventarioInicialSchema
from src.service import stg_inventario_inicial_service

def get_all():
    return stg_inventario_inicial_service.get_all()

def create(data: StgInventarioInicialSchema):
    stg_inventario_inicial_service.create(data )
    return {"message": "Registro cargado correctamente"}

def delete(item, lote):
    stg_inventario_inicial_service.delete(item, lote)
    return {"message": "Se eliminó el registro"}
