from fastapi import APIRouter
from src.schemas.usuario_schema import Login, UsuarioCreate, UsuarioUpdate
from src.controllers import usuario_controller

router = APIRouter(prefix="/usuarios")

@router.get("/")
def find_all():
    return usuario_controller.find_all()

@router.get("/filtro")
def find_all_with_pagination(keyboard: str | None = "", page: int = 1, elementsPerPages: int = 10):
    return usuario_controller.find_all_by_keyword_and_pagination(filter=keyboard, pages=page, elementPerPages=elementsPerPages)



@router.get("/id/{id_usuario}")
def find_one(id_usuario: int):
    return usuario_controller.find_one(id_usuario)

@router.post("/auth")
def login(usr: Login):
    return usuario_controller.login(usr)

@router.post("/")
def create(data: UsuarioCreate):
    return usuario_controller.create(data)

@router.put("/{id_usuario}")
def update(id_usuario: int, data: UsuarioUpdate):
    return usuario_controller.update(id_usuario, data)

@router.delete("/{id_usuario}")
def delete(id_usuario: int):
    return usuario_controller.delete(id_usuario)
