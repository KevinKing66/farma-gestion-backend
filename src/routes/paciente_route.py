from fastapi import APIRouter
from src.controllers import paciente_controller
from src.schemas.paciente_schema import PatientCreate, PatientUpdate

router = APIRouter(prefix="/pacientes")


@router.get("/")
def get_all_route():
    return paciente_controller.find_all()


@router.get("/filtro")
def find_all_with_pagination_route(
    keyword: str = "",
    page: int = 1,
    limit: int = 10
):
    return paciente_controller.find_all_with_pagination(keyword, page, limit)


@router.post("/")
def create_route(patient: PatientCreate):
    return paciente_controller.create(patient)

@router.put("/update/{id_paciente}")
def update(id_paciente: int, data: PatientUpdate):
    return paciente_controller.update(id_paciente, data)

@router.put("/update_last_attention_date/{id_paciente}")
def update_last_attention_date(id_paciente: int):
    return paciente_controller.update_last_attention_date(id_paciente)


@router.delete("/{id_paciente}")
def delete_route(id_paciente: int):
    return paciente_controller.delete(id_paciente)


@router.delete("/")
def delete_ctx_route(id_paciente: int, id_usuario):
    return paciente_controller.delete_ctx(id_paciente, id_usuario)


@router.get("/id/{id_paciente}")
def get_one_route(id_paciente: int):
    return paciente_controller.find_by_id(id_paciente)
