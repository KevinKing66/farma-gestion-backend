from http.client import HTTPException
from src.schemas.auditoria_schema import AuditoriaBase
from src.service import auditoria_service

def get_all():
    try:
        return auditoria_service.get_all_auditorias()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_one(id_evento):
    try:
        return auditoria_service.get_auditoria_by_id(id_evento)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_by_tabla(tabla_afectada: str):
    try:
        return auditoria_service.get_auditorias_by_tabla(tabla_afectada)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def create(data:AuditoriaBase):
    try:
        auditoria_service.create_auditoria(
            data.tabla_afectada,
            data.pk_afectada,
            data.accion,
            data.valores_antes,
            data.valores_despues,
            data.id_usuario,
            data.hash_anterior,
            data.hash_evento
        )
        return {"message": "Evento de auditoría registrado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
