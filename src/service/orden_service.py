from src.config.database import get_connection
from src.schemas.orden_schema import OrdenCreate, OrdenDetalleCreate, OrdenDetalleUpdate, OrdenEstadoUpdate


def find_all_with_pagination(keyword: str, page: int, limit: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.callproc("sp_buscar_ordenes", [keyword, page, limit])

        result_sets = list(cursor.stored_results())

        ordenes = result_sets[0].fetchall()

        metadata = result_sets[1].fetchall()[0]

        return {
            "data": ordenes,
            "metadata": metadata
        }

    except Exception as e:
        print(f"Error en sp_buscar_ordenes: {e}")
        raise e

    finally:
        cursor.close()
        conn.close()



def find_all_with_pagination_v2(keyword: str, status: str, page: int, limit: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.callproc("sp_buscar_ordenes_v2", [keyword, status, page, limit])

        result_sets = list(cursor.stored_results())

        ordenes = result_sets[0].fetchall()

        metadata = result_sets[1].fetchall()[0]

        return {
            "data": ordenes,
            "metadata": metadata
        }

    except Exception as e:
        print(f"Error en sp_buscar_ordenes_v2: {e}")
        raise e

    finally:
        cursor.close()
        conn.close()


def crear_orden(orden: OrdenCreate):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc("sp_crear_orden_ctx", [
            orden.id_paciente,
            orden.id_usuario,
            orden.observaciones
        ])

        for result in cursor.stored_results():
            return result.fetchone()
    except Exception as e:
        print("Error en orden_Service: ", e)
        raise Exception(f"Error: {e}")

    finally:
        cursor.close()
        conn.close()


def add_details(id_orden: int, detalle: OrdenDetalleCreate):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("sp_agregar_detalle_orden_ctx", [
            id_orden,
            detalle.id_item,
            detalle.cantidad,
            detalle.id_usuario
        ])
        conn.commit()
        return {"message": "Detalle agregado"}
    except Exception as e:
        print("Error en orden_Service: ", e)
        raise Exception(f"Error: {e}")
    finally:
        cursor.close()
        conn.close()


def update_estado(id_orden: int, estado: str, id_usuario: int):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("sp_actualizar_estado_orden_ctx", [
            id_orden,
            estado,
            id_usuario
        ])
        conn.commit()
        return {"message": "Estado actualizado"}
    except Exception as e:
        print("Error en orden_Service: ", e)
        raise Exception(f"Error: {e}")
    finally:
        cursor.close()
        conn.close()


def find_detail(id_orden: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc("sp_obtener_detalle_orden", [id_orden])
        for result in cursor.stored_results():
            return result.fetchall()
    except Exception as e:
        print("Error en orden_Service: ", e)
        raise Exception(f"Error: {e}")
    finally:
        cursor.close()
        conn.close()


def update_details(detalle: OrdenDetalleUpdate):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("sp_actualizar_detalle_orden_ctx", [
            detalle.id_detalle,
            detalle.id_orden,
            detalle.id_item,
            detalle.cantidad,
            detalle.id_usuario
        ])
        conn.commit()
        return {"message": "Detalle actualizado"}
    except Exception as e:
        print("Error en orden_Service: ", e)
        raise Exception(f"Error: {e}")
    finally:
        cursor.close()
        conn.close()


def delete(id_orden: int, id_usuario: int):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("sp_eliminar_orden_ctx", [
            id_orden,
            id_usuario
        ])
        conn.commit()
        return {"message": "Orden eliminada"}
    except Exception as e:
        print("Error en orden_Service: ", e)
        raise Exception(f"Error: {e}")
    finally:
        cursor.close()
        conn.close()
        

def updateLastAttentionDate(id_paciente):
    try:
        connection = get_connection()
        cursor = connection.cursor()
        cursor.callproc("sp_actualizar_ultima_atencion", [id_paciente])
        connection.commit()

        cursor.close()
        connection.close()
        return {"message": "Paciente actualizado"}

    except Exception as e:
        print("Error in orden_service.update:", e)
        raise Exception("Error al actualizar el paciente")
