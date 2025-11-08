from typing import Any, Dict, List, cast
from src.models.ubicacion_model import Ubicacion
from src.config.database import get_connection

def get_all_ubicaciones() -> List[Ubicacion]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("CALL sp_listar_ubicaciones()")
    results = cursor.fetchall()
    cursor.close()
    conn.close()

    return [Ubicacion(**cast(Dict[str, Any], row)) for row in results]

def get_ubicacion_by_id(id_ubicacion):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("CALL sp_obtener_ubicacion(%s)", (id_ubicacion,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return Ubicacion(**cast(Dict[str, Any], result)) if result else None

def create_ubicacion(nombre, tipo, activo):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "CALL sp_crear_ubicacion(%s, %s, %s)",
        (nombre, tipo, activo)
    )
    conn.commit()
    cursor.close()
    conn.close()

def update_ubicacion(id_ubicacion, nombre, tipo, activo):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "CALL sp_actualizar_ubicacion(%s, %s, %s, %s)",
        (id_ubicacion, nombre, tipo, activo,)
    )
    conn.commit()
    cursor.close()
    conn.close()

def delete_ubicacion(id_ubicacion):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("CALL sp_eliminar_ubicaciones(%s)", (id_ubicacion,))
    conn.commit()
    cursor.close()
    conn.close()
