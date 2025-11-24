from fastapi import HTTPException
from src.service import existencia_service

def get_all():
    try:
        return existencia_service.get_all_existencias()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_one(id_existencia):
    try:
        return existencia_service.get_existencia_by_id(id_existencia)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data):
    try:
        existencia_service.create_existencia(
            data["id_lote"],
            data["id_ubicacion"],
            data["saldo"]
        )
        return {"message": "Existencia creada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update(id_existencia, data):
    try:
        existencia_service.update_existencia(
            id_existencia,
            data["id_lote"],
            data["id_ubicacion"],
            data["saldo"]
        )
        return {"message": "Existencia actualizada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete(id_existencia):
    try:
        existencia_service.delete_existencia(id_existencia)
        return {"message": "Existencia eliminada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
