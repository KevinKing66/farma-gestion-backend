from fastapi import HTTPException
from src.service.reportes_service import (
    find_medicines_delivered_month,
    find_resolved_alerts,
    find_completed_orders,
    find_medicines_by_week,
    find_orders_month
)


def medicines_delivered_month():
    try:
        return find_medicines_delivered_month()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def alerts_resolved():
    try:
        return find_resolved_alerts()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def completed_orders():
    try:
        return find_completed_orders()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def medicines_by_week():
    try:
        return find_medicines_by_week()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def orders_month():
    try:
        return find_orders_month()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
