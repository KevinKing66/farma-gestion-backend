from fastapi import HTTPException
from src.schemas.stg_inventario_inicial_schema import StgInventarioInicialSchema
from src.service import stg_inventario_inicial_service

def get_all():
    try:
        return stg_inventario_inicial_service.get_all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data: StgInventarioInicialSchema):
    try:
        stg_inventario_inicial_service.create(data )
        return {"message": "Registro cargado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete(item, lote):
    try:
        stg_inventario_inicial_service.delete(item, lote)
        return {"message": "Se eliminó el registro"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
