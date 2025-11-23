from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.config.base import Base
from src.routes import (
    lote_route, item_route, auditoria_route, comprobante_route, existencia_route,
    proveedor_route, usuario_route, ubicacion_route, movimiento_route,
    notificacion_route, parametro_route, staging_inventario_inicial_route,
    backup_route, control_calidad_route, incidente_route, ip_route, token_route,
    dashboard_router, inventario_route, paciente_route, orden_route
)
# from src.routes import lote_route, item_route, auditoria_route, comprobante_route, existencia_route, proveedor_route, usuario_route, ubicacion_route, movimiento_route, notificacion_route, parametro_route, staging_inventario_inicial_route, backup_route, control_calidad_route, incidente_route, ip_route, token_route, dashboard_router, inventario_route 

app = FastAPI(title="Farma Gestión Backend")


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auditoria_route.router)
app.include_router(comprobante_route.router)
app.include_router(existencia_route.router)
app.include_router(item_route.router)
app.include_router(lote_route.router)
app.include_router(movimiento_route.router)
app.include_router(notificacion_route.router)
app.include_router(parametro_route.router)
app.include_router(proveedor_route.router)
app.include_router(staging_inventario_inicial_route.router)
app.include_router(ubicacion_route.router)
app.include_router(usuario_route.router)
app.include_router(backup_route.router)
app.include_router(control_calidad_route.router)
app.include_router(incidente_route.router)
app.include_router(ip_route.router)
app.include_router(token_route.router)
app.include_router(dashboard_router.router)

app.include_router(inventario_route.router)

app.include_router(paciente_route.router)
app.include_router(orden_route.router)
