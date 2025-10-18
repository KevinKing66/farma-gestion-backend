from src.config.database import get_connection

def get_all_items():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT i.*, u.nombre AS nombre_ubicacion
        FROM items i
        INNER JOIN ubicaciones u ON i.id_ubicacion = u.id_ubicacion
    """)
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


def get_item_by_id(id_item):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT i.*, u.nombre AS nombre_ubicacion
        FROM items i
        INNER JOIN ubicaciones u ON i.id_ubicacion = u.id_ubicacion
        WHERE i.id_item = %s
    """, (id_item,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result


def create_item(id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO items (id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo))
    conn.commit()
    cursor.close()
    conn.close()


def update_item(id_item, id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE items
        SET id_ubicacion=%s, codigo=%s, descripcion=%s, tipo_item=%s, unidad_medida=%s, stock_minimo=%s
        WHERE id_item=%s
    """, (id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo, id_item))
    conn.commit()
    cursor.close()
    conn.close()


def delete_item(id_item):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM items WHERE id_item=%s", (id_item,))
    conn.commit()
    cursor.close()
    conn.close()
