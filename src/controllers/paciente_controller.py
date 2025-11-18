from src.service.paciente_service import (
    get_all,
    find_all_with_pagination,
    create,
    update,
    delete,
    get_by_id
)


def find_all():
    return get_all()


def find_all_with_pagination(filter_value, page, limit):
    return find_all_with_pagination(filter_value, page, limit)


def create(data):
    return create(
        data.tipo_documento,
        data.documento,
        data.nombre_completo,
        data.fecha_ingreso
    )


def update(id_paciente):
    return update(id_paciente)


def delete(id_paciente):
    return delete(id_paciente)


def find_by_id(id_paciente):
    return get_by_id(id_paciente)
