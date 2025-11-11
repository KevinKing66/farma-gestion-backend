from src.service.dashboard_service import (
    get_dashboard_auxiliar,
    get_dashboard_regente,
    get_dashboard_auditor,
    get_dashboard_proveedor
)

def obtener_dashboard_auxiliar():
    return get_dashboard_auxiliar()

def obtener_dashboard_regente():
    return get_dashboard_regente()

def obtener_dashboard_auditor():
    return get_dashboard_auditor()

def obtener_dashboard_proveedor():
    return get_dashboard_proveedor()
