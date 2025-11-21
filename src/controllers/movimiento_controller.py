from src.service import movimiento_service
from fastapi import APIRouter, Query


def get_all():
    return movimiento_service.get_all()

def get_by_lote(id_lote: int):
    return movimiento_service.get_by_lote(id_lote)

def registrar_ingreso(data):
    movimiento_service.registrar_ingreso(data)
    return {"message": "Ingreso registrado correctamente"}

def registrar_salida(data):
    movimiento_service.registrar_salida(data)
    return {"message": "Salida registrada correctamente"}

def crear_lote(data):
    result = movimiento_service.crear_lote(data)
    return result

def registrar_ingreso(data):
    movimiento_service.registrar_ingreso(data)
    return {"message": "Ingreso registrado correctamente"}

def transferir_stock(data):
    return movimiento_service.transferir_stock(data)
    