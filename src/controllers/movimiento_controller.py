from src.service import movimiento_service
from fastapi import APIRouter, Query


def get_all():
    return movimiento_service.get_all()

def get_by_lote(id_lote: int):
    return movimiento_service.get_by_lote(id_lote)
    