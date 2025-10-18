from src.config.database import get_connection

def get_all_usuarios():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM usuarios")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result


def get_usuario_by_id(id_usuario):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM usuarios WHERE id_usuario = %s", (id_usuario,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result


def create_usuario(nombre_completo, correo, rol, contrasena, intentos_fallidos=0, bloqueado_hasta=None):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO usuarios (nombre_completo, correo, rol, contrasena, intentos_fallidos, bloqueado_hasta)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (nombre_completo, correo, rol, contrasena, intentos_fallidos, bloqueado_hasta)
    )
    conn.commit()
    cursor.close()
    conn.close()


def update_usuario(id_usuario, nombre_completo, correo, rol, contrasena, intentos_fallidos, bloqueado_hasta):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE usuarios 
        SET nombre_completo=%s, correo=%s, rol=%s, contrasena=%s, intentos_fallidos=%s, bloqueado_hasta=%s
        WHERE id_usuario=%s
        """,
        (nombre_completo, correo, rol, contrasena, intentos_fallidos, bloqueado_hasta, id_usuario)
    )
    conn.commit()
    cursor.close()
    conn.close()


def delete_usuario(id_usuario):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM usuarios WHERE id_usuario = %s", (id_usuario,))
    conn.commit()
    cursor.close()
    conn.close()
