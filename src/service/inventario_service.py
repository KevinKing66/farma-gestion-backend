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
