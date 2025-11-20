from fastapi import HTTPException
from src.service import usuario_service
from src.schemas.usuario_schema import Login, UsuarioCreate, UsuarioUpdate

def find_all():
    return usuario_service.find_all()


def find_all_by_keyword_and_pagination(filter: str = 0, pages: int = 0, elementPerPages: int = 10):
    
    try:
        return usuario_service.find_all_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)
    except Exception as e:
        return {"error": str(e)}


def find_one(id_usuario: int):
    return usuario_service.get_usuario_by_id(id_usuario)

def login(user: Login):
    try:
        return usuario_service.login(user)
    except Exception as error:
        print(f"Error: {error}")
        raise HTTPException(status_code=403, detail=str(error))

def create(user: UsuarioCreate):
    try:
        usuario_service.create_usuario(user)
        return {"message": "Usuario creado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

def update(id_usuario, data: UsuarioUpdate):
    usuario_service.update_usuario(
        id_usuario,
        data
    )
    return {"message": "Usuario actualizado correctamente"}

def delete(id_usuario: int):
    usuario_service.delete_usuario(id_usuario)
    return {"message": "Usuario eliminado correctamente"}
