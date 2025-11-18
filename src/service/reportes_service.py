from src.config.database import get_connection


def find_medicines_delivered_month():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_reportes_medicamentos_entregados_mes")

        row = None
        for result in cursor.stored_results():
            row = result.fetchone()

        cursor.close()
        connection.close()

        return row

    except Exception as e:
        print("❌ Error en reportes_servicio.find_medicines_delivered_month:", e)
        raise Exception("Error obteniendo medicamentos entregados del mes")


def find_resolved_alerts():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_reportes_alertas_resueltas")

        row = None
        for result in cursor.stored_results():
            row = result.fetchone()

        cursor.close()
        connection.close()

        return row

    except Exception as e:
        print("❌ Error en reportes_servicio.find_resolved_alerts:", e)
        raise Exception("Error obteniendo alertas resueltas")


def find_completed_orders():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_reportes_pedidos_completados")

        row = None
        for result in cursor.stored_results():
            row = result.fetchone()

        cursor.close()
        connection.close()

        return row

    except Exception as e:
        print("❌ Error en reportes_servicio.find_completed_orders:", e)
        raise Exception("Error obteniendo pedidos completados")


def find_medicines_by_week():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_reportes_medicamentos_entregados_por_semana")

        data = []
        for result in cursor.stored_results():
            data = result.fetchall()

        cursor.close()
        connection.close()

        return data

    except Exception as e:
        print("❌ Error en reportes_servicio.find_medicines_by_week:", e)
        raise Exception("Error obteniendo medicamentos entregados por semana")


def find_orders_month():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_reportes_ordenes_mes")

        data = []
        for result in cursor.stored_results():
            data = result.fetchall()

        cursor.close()
        connection.close()

        return data

    except Exception as e:
        print("❌ Error en reportes_servicio.find_orders_month:", e)
        raise Exception("Error obteniendo órdenes del mes")
