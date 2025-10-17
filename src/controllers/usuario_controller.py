from services import usuario_service

def get_all():
    return usuario_service.get_all_usuarios()

def get_one(id_usuario):
    return usuario_service.get_usuario_by_id(id_usuario)

def create(data):
    usuario_service.create_usuario(
        data["nombre_completo"],
        data["correo"],
        data["rol"],
        data["contrasena"],
        data.get("intentos_fallidos", 0),
        data.get("bloqueado_hasta", None)
    )
    return {"message": "Usuario creado correctamente"}

def update(id_usuario, data):
    usuario_service.update_usuario(
        id_usuario,
        data["nombre_completo"],
        data["correo"],
        data["rol"],
        data["contrasena"],
        data.get("intentos_fallidos", 0),
        data.get("bloqueado_hasta", None)
    )
    return {"message": "Usuario actualizado correctamente"}

def delete(id_usuario):
    usuario_service.delete_usuario(id_usuario)
    return {"message": "Usuario eliminado correctamente"}
