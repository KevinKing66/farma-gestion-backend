from fastapi import FastAPI
from src.config.base import Base
from src.routes import lote_route, item_route, auditoria_route, comprobante_route, existencia_route, proveedor_route, usuario_route, ubicacion_route

app = FastAPI(title="Farma Gestión Backend")

app.include_router(lote_route.router)
app.include_router(item_route.router)
app.include_router(ubicacion_route.router)
app.include_router(auditoria_route.router)
app.include_router(proveedor_route.router)
app.include_router(comprobante_route.router)
app.include_router(usuario_route.router)
app.include_router(existencia_route.router)

# app.include_router(venta_route.router)
