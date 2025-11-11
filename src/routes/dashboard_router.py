from fastapi import APIRouter
from src.controllers import dashboard_controller as controller
from typing import List

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/auxiliar", response_model=List)
def get_auxiliar_dashboard():
    return controller.obtener_dashboard_auxiliar()

@router.get("/regente", response_model=List)
def get_regente_dashboard():
    return controller.obtener_dashboard_regente()

@router.get("/auditor", response_model=List)
def get_auditor_dashboard():
    return controller.obtener_dashboard_auditor()

@router.get("/proveedor", response_model=List)
def get_proveedor_dashboard():
    return controller.obtener_dashboard_proveedor()
