from src.service.reportes_service import (
    find_medicines_delivered_month,
    find_resolved_alerts,
    find_completed_orders,
    find_medicines_by_week,
    find_orders_month
)


def medicines_delivered_month():
    return find_medicines_delivered_month()


def alerts_resolved():
    return find_resolved_alerts()


def completed_orders():
    return find_completed_orders()


def medicines_by_week():
    return find_medicines_by_week()


def orders_month():
    return find_orders_month()
