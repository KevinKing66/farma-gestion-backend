from src.config.database import get_connection

def find_all_proveedores():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("CALL sp_listar_proveedores()")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


def find_all_by_keyword_and_pagination(filter: str, pages: int = 0, elementPerPages: int = 10):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc('sp_buscar_proveedores', [filter, pages, elementPerPages])
        data = []
        for result in cursor.stored_results():
            data = result.fetchall()
        cursor.close()
        connection.close()
        return data
    except Exception as e:
        print(f"Error en sp_buscar_proveedores: {e}")
        raise Exception("Error al buscar proveedores")


def find_by_id(id_proveedor):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("CALL sp_obtener_proveedor(%s)", (id_proveedor,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result


def create_proveedor(nombre, nit):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "CALL sp_crear_proveedor(%s, %s)",
        (nombre, nit)
    )
    conn.commit()
    cursor.close()
    conn.close()


def update_proveedor(id_proveedor, nombre, nit):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "CALL sp_actualizar_proveedor(%s)",
        (id_proveedor, nombre, nit,)
    )
    conn.commit()
    cursor.close()
    conn.close()


def delete_proveedor(id_proveedor):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM proveedores WHERE id_proveedor = %s", (id_proveedor,))
    conn.commit()
    cursor.close()
    conn.close()
