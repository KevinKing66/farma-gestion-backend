from typing import List

from src.config.database import get_connection

def get_dashboard_auxiliar() -> list:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM v_dashboard_auxiliar;")
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    return results


def get_dashboard_regente() -> list:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM v_dashboard_regente;")
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    return results


def get_dashboard_auditor() -> list:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM v_dashboard_auditor;")
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    return results


def get_dashboard_proveedor() -> list:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM v_dashboard_proveedor;")
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    return results
