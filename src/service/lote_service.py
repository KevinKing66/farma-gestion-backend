import mysql
from src.config.database import get_connection

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


def create_lote(id_item, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc(
            "sp_crear_lote",
            (id_item, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario)
        )

        # ✅ Consumir el resultado del SELECT dentro del SP
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
