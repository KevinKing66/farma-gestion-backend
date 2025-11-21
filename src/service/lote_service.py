import mysql

from src.schemas.item_schema import ItemTranferir
from src.config.database import get_connection
from src.schemas.lote_schema import LoteCreate, LoteUpdate

def get_all_lotes():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT l.*, 
               i.descripcion AS item_descripcion,
               p.nombre AS proveedor_nombre
        FROM lotes l
        INNER JOIN items i ON l.id_item = i.id_item
        INNER JOIN proveedores p ON l.id_proveedor = p.id_proveedor
    """)
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


def get_lote_by_id(id_lote):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc('sp_obtener_detalle_lote', [id_lote])

        data = []
        for result in cursor.stored_results():
            data = result.fetchall()

        cursor.close()
        connection.close()
        return data

    except Exception as e:
        print(f"Error en obtener_detalle_lote: {e}")
        raise Exception("Error al obtener detalle del lote")


def create_lote(lote: LoteCreate):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc(
            "sp_crear_lote",
            (lote.id_item, lote.nombre_item, lote.unidad_medida, lote.stock_minimo, lote.id_proveedor, lote.codigo_lote, lote.fecha_vencimiento, lote.costo_unitario, lote.id_ubicacion_destino, lote.cantidad, lote.id_usuario, lote.motivo)
        )

        result = None
        for res in cursor.stored_results():
            result = res.fetchone()  # obtiene {"id_lote": valor}

        conn.commit()
        return result  # puedes retornar el id del lote si lo necesitas

    except mysql.connector.Error as err: # type: ignore
        conn.rollback()
        raise err
    finally:
        cursor.close()
        conn.close()



def update_lote(id_item, fecha_vencimiento, costo_unitario):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("CALL sp_actualizar_lote(%s, %s, %s)", (id_item, fecha_vencimiento, costo_unitario))
    conn.commit()
    cursor.close()
    conn.close()


def delete_lote(id_lote):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("CALL sp_eliminar_lote(%s)", (id_lote,))
    conn.commit()
    cursor.close()
    conn.close()


def update_location(data: ItemTranferir):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.callproc(
            "sp_transferir_stock",
            [
                data.id_lote,
                data.id_ubicacion_origen,
                data.id_ubicacion_destino,
                data.cantidad,
                data.id_usuario,
                data.motivo
            ]
        )

        result = None
        for res in cursor.stored_results():
            result = res.fetchall()

        conn.commit()

        return {
            "status": "success",
            "message": "Stock transferido correctamente",
            "result": result
        }

    except mysql.connector.Error as err:  # type: ignore
        conn.rollback()
        raise Exception(str(err))

    finally:
        cursor.close()
        conn.close()


def find_all_with_pagination(filter_value, page, limit):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_listar_lotes", [filter_value, page, limit])

        data = []
        for result in cursor.stored_results():
            data = result.fetchall()

        cursor.close()
        connection.close()

        return data

    except Exception as e:
        print("Error in paciente_service.find_all_with_pagination:", e)
        raise Exception("Error al buscar pacientes con paginacion")
