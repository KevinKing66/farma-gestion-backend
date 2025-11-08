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
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT l.*, 
               i.descripcion AS item_descripcion,
               p.nombre AS proveedor_nombre
        FROM lotes l
        INNER JOIN items i ON l.id_item = i.id_item
        INNER JOIN proveedores p ON l.id_proveedor = p.id_proveedor
        WHERE l.id_lote = %s
    """, (id_lote,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result


def create_lote(id, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
       CALL sp_crear_lote(%s, %s, %s, %s, %s)
    """, (id, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario))
    conn.commit()
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
