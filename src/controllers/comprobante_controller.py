from http.client import HTTPException
from src.service import comprobante_service

def find_all():
    try:
        return comprobante_service.get_all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def find_one(id_comprobante):
    try:
        return comprobante_service.get_by_id(id_comprobante)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def find_all_by_proveedor(id_comprobante):
    try:
        return comprobante_service.find_all_by_proveedor(id_comprobante)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data):
    try:
        comprobante_service.create_comprobante(
            data["id_movimiento"],
            data["id_proveedor"],
            data.get("canal", "PORTAL")
        )
        return {"message": "Comprobante registrado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def marcar_entregado(id_comprobante):
    try:
        comprobante_service.marcar_entregado(id_comprobante)
        return {"message": "Comprobante marcado como entregado"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete(id_comprobante):
    try:
        comprobante_service.delete_comprobante(id_comprobante)
        return {"message": "Comprobante eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))