from src.config.database import get_connection

def find_all_inventario():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc('sp_listar_inventario')
        data = []
        for result in cursor.stored_results():
            data = result.fetchall()
        cursor.close()
        connection.close()
        return data
    except Exception as e:
        print(f"Error en listar_inventario: {e}")
        raise Exception("Error al listar inventario")

def find_all_inventario_by_keyword_and_pagination(filter: str, pages: int = 0, elementPerPages: int = 10):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc('sp_buscar_inventario', [filter, pages, elementPerPages])
        data = []
        for result in cursor.stored_results():
            data = result.fetchall()
        cursor.close()
        connection.close()
        return data
    except Exception as e:
        print(f"Error en buscar_inventario: {e}")
        raise Exception("Error al buscar inventario")

def get_medicamento_by_keyword_and_pagination(filter: str, pages: int = 0, elementPerPages: int = 10):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc('sp_buscar_medicamento', [filter, pages, elementPerPages])
        data = []
        for result in cursor.stored_results():
            data = result.fetchall()
        cursor.close()
        connection.close()
        return data
    except Exception as e:
        print(f"Error en sp_buscar_medicamento: {e}")
        raise Exception("Error al buscar inventario")


def exportar_inventario():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("sp_exportar_inventario")

        results = []
        for stored in cursor.stored_results():
            rows = stored.fetchall()
            cols = [d[0] for d in stored.description]
            for row in rows:
                results.append(dict(zip(cols, row)))

        return results

    finally:
        cursor.close()
        conn.close()


def stockAdjust(
        id_lote,
        id_ubicacion,
        cantidad,
        sentido,
        id_usuario,
        motivo
):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("sp_ajustar_stock_ctx", [
            id_lote,
            id_ubicacion,
            cantidad,
            sentido,
            id_usuario,
            motivo
        ])

        conn.commit()
        return {"message": "Stock ajustado correctamente"}

    except Exception as e:
        print("Error en stock_service.ajustar_stock:", e)
        raise Exception("Error al ajustar stock")

    finally:
        cursor.close()
        conn.close()
