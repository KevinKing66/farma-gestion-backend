from fastapi import HTTPException
from src.schemas.lote_schema import LoteCreate, LoteUpdate
from src.service import lote_service
from src.schemas.exportar_inventario_schema import ExportarInventarioResponseSchema


def get_all():
    return lote_service.get_all_lotes()

def get_all_by_lote():
    return lote_service.get_all_lotes()

def find_all_with_pagination(filter, page, elementPerPages):
    return lote_service.find_all_with_pagination(filter, page, elementPerPages)

def get_one(id_lote):
    return lote_service.get_lote_by_id(id_lote)

def create(data: LoteCreate):
    return lote_service.create_lote(lote=data)

def update(id, data: LoteUpdate):
    lote_service.update_lote(
        id,
        data.fecha_vencimiento,
        data.costo_unitario
    )
    return {"message": "Lote actualizado correctamente"}

def delete(id_lote):
    lote_service.delete_lote(id_lote)
    return {"message": "Lote eliminado correctamente"}
