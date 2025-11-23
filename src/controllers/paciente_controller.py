from src.service import paciente_service
from src.schemas.paciente_schema import PatientCreate, PatientUpdate


def find_all():
    return paciente_service.get_all()


def find_all_with_pagination(filter, page, limit):
    return paciente_service.find_all_with_pagination(filter, page, limit)


def create(data: PatientCreate):
    return paciente_service.create(
        data.tipo_documento,
        data.documento,
        data.nombre_completo,
        data.fecha_ingreso,
        data.id_usuario
    )

def update(id_paciente: int, data: PatientUpdate):
    return paciente_service.update(id_paciente, data)

def update_last_attention_date(id_paciente):
    return paciente_service.updateLastAttentionDate(id_paciente)


def delete(id_paciente):
    return paciente_service.delete(id_paciente)

def delete_ctx(id_paciente, id_usuario):
    return paciente_service.delete_ctx(id_paciente, id_usuario)


def find_by_id(id_paciente):
    return paciente_service.get_by_id(id_paciente)
