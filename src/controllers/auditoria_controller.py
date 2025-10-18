from src.service import auditoria_service

def get_all():
    return auditoria_service.get_all_auditorias()

def get_one(id_evento):
    return auditoria_service.get_auditoria_by_id(id_evento)

def get_by_tabla(tabla_afectada: str):
    return auditoria_service.get_auditorias_by_tabla(tabla_afectada)

def create(data):
    auditoria_service.create_auditoria(
        data["tabla_afectada"],
        data["pk_afectada"],
        data["accion"],
        data.get("valores_antes"),
        data.get("valores_despues"),
        data.get("id_usuario"),
        data.get("hash_anterior"),
        data["hash_evento"]
    )
    return {"message": "Evento de auditoría registrado correctamente"}

def delete(id_evento):
    auditoria_service.delete_auditoria(id_evento)
    return {"message": "Evento de auditoría eliminado correctamente"}
