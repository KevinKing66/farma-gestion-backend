from fastapi import HTTPException
from src.service import usuario_service
from src.schemas.usuario_schema import Login, UsuarioCreate, UsuarioUpdate

def get_all():
    return usuario_service.get_all_usuarios()

def get_one(id_usuario: int):
    return usuario_service.get_usuario_by_id(id_usuario)

def login(user: Login):
    try:
        return usuario_service.login(user)
    except Exception as e:
        raise HTTPException(status_code=403, detail=str(e))

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
