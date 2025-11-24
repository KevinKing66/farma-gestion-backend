from fastapi import HTTPException
from src.service import paciente_service
from src.schemas.paciente_schema import PatientCreate, PatientUpdate


def find_all():
    return paciente_service.get_all()


def find_all_with_pagination(filter, page, limit):
    try:
        return paciente_service.find_all_with_pagination(filter, page, limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def create(data: PatientCreate):
    try:
        return paciente_service.create(
            data.tipo_documento,
            data.documento,
            data.nombre_completo,
            data.fecha_ingreso,
            data.id_usuario
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update(id_paciente: int, data: PatientUpdate):
    try:
        return paciente_service.update(id_paciente, data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update_last_attention_date(id_paciente):
    try:
        return paciente_service.updateLastAttentionDate(id_paciente)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def update_last_attention_date_ctx(id_paciente, id_usuario):
    try:
        return paciente_service.updateLastAttentionDateCtx(id_paciente, id_usuario)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def delete(id_paciente):
    try:
        return paciente_service.delete(id_paciente)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def delete_ctx(id_paciente, id_usuario):
    try:
        return paciente_service.delete_ctx(id_paciente, id_usuario)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def find_by_id(id_paciente):
    try:
        return paciente_service.get_by_id(id_paciente)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
