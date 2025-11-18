from fastapi import APIRouter
from src.controllers import reportes_controller

router = APIRouter(prefix="/reportes")

@router.get("/medicinas/mes")
def route_medicines_month():
    return reportes_controller.medicines_delivered_month()


@router.get("/medicinas/semana")
def route_medicines_week():
    return reportes_controller.medicines_by_week()


@router.get("/alertas/resueltas")
def route_alerts_resolved():
    return reportes_controller.alerts_resolved()


@router.get("/ordernes/completadas")
def route_orders_completed():
    return reportes_controller.completed_orders()


@router.get("/ordernes/mes")
def route_orders_month():
    return reportes_controller.orders_month()
