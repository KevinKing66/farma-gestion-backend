from src.config.database import get_connection


def get_all():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT mv.id_movimiento, mv.tipo, mv.cantidad, mv.fecha,
               mv.motivo, l.codigo_lote, u.usuario AS usuario,
               ori.nombre AS origen, des.nombre AS destino
        FROM movimientos_v2 mv
        JOIN lotes l ON mv.id_lote = l.id_lote
        JOIN usuarios u ON mv.id_usuario = u.id_usuario
        LEFT JOIN ubicaciones ori ON mv.id_ubicacion_origen = ori.id_ubicacion
        LEFT JOIN ubicaciones des ON mv.id_ubicacion_destino = des.id_ubicacion
        ORDER BY mv.fecha DESC
    """)
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


def insert_movimiento(
    id_lote,
    id_usuario,
    tipo,
    cantidad,
    id_ubicacion_origen,
    id_ubicacion_destino,
    motivo
):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.callproc("sp_registrar_movimiento", [
        id_lote,
        id_usuario,
        tipo,
        cantidad,
        id_ubicacion_origen,
        id_ubicacion_destino,
        motivo
    ])
    conn.commit()
    cursor.close()
    conn.close()


def get_by_lote(id_lote):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT * FROM movimientos_v2 WHERE id_lote = %s ORDER BY fecha DESC
    """, (id_lote,))
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result

def registrar_salida(data):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.callproc("sp_registrar_salida", [
        data.p_id_lote,
        data.p_id_ubicacion_origen,
        data.p_id_ubicacion_destino,
        data.p_cantidad,
        data.p_id_usuario,
        data.p_motivo
    ])
    conn.commit()
    cursor.close()
    conn.close()

def crear_lote(data):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.callproc("sp_crear_lote", [
        data.p_id_item,
        data.p_nombre_item,
        data.p_unidad_medida,
        data.p_stock_minimo,
        data.p_id_proveedor,
        data.p_codigo_lote,
        data.p_fecha_vencimiento,
        data.p_costo_unitario,
        data.p_id_ubicacion_destino,
        data.p_cantidad,
        data.p_id_usuario,
        data.p_motivo
    ])

    # El SP hace un SELECT final → debemos recogerlo
    result = None
    for dataset in cursor.stored_results():
        result = dataset.fetchall()

    conn.commit()
    cursor.close()
    conn.close()

    return result

def registrar_ingreso(data):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.callproc("sp_registrar_ingreso", [
            data.p_id_item,
            data.p_id_proveedor,
            data.p_codigo_lote,
            data.p_fecha_venc,
            data.p_costo_unitario,
            data.p_id_ubicacion_destino,
            data.p_cantidad,
            data.p_id_usuario,
            data.p_motivo
        ])

        conn.commit()

    except Exception as e:
        conn.rollback()
        raise e

    finally:
        cursor.close()
        conn.close()

def transferir_stock(data):

    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.callproc(
                "sp_transferir_stock",
                [
                    data.p_id_lote,
                    data.p_id_ubicacion_origen,
                    data.p_id_ubicacion_destino,
                    data.p_cantidad,
                    data.p_id_usuario,
                    data.p_motivo
                ]
            )
        connection.commit()
        return {"message": "Transferencia realizada correctamente"}

    except Exception as e:
        connection.rollback()
        raise e

    finally:
        connection.close()