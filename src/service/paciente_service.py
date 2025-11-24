from src.config.database import get_connection
from src.models.paciente_model import Paciente
from src.schemas.paciente_schema import PatientUpdate



def get_all():
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_listar_pacientes")

        data = []
        for result in cursor.stored_results():
            data = result.fetchall()

        cursor.close()
        connection.close()

        return [Paciente.from_db_row(row).to_dict() for row in data]

    except Exception as e:
        print("Error in paciente_service.find_all:", e)
        raise Exception("Error buscando todos los pacientes")


def find_all_with_pagination(keyword: str, page: int = 1, limit: int = 10):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.callproc("sp_buscar_paciente", [keyword, page, limit])

        result_sets = list(cursor.stored_results())

        pacientes = result_sets[0].fetchall()

        metadata = result_sets[1].fetchall()[0]

        cursor.close()
        connection.close()

        return {
            "data": [Paciente.from_db_row(row).to_dict() for row in pacientes],
            "metadata": metadata
        }

    except Exception as e:
        print("Error en find_all_by_keyword_and_pagination:", e)
        raise Exception(f"Error al buscar pacientes: \n {e}")



def create(tipo_documento, documento, nombre_completo, fecha_ingreso, id_usuario):
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_crear_paciente_ctx", [
            tipo_documento, documento, nombre_completo, fecha_ingreso, id_usuario
        ])

        new_id = None
        for result in cursor.stored_results():
            new_id = result.fetchone()["id_paciente"]

        connection.commit()
        cursor.close()
        connection.close()

        return {"id_paciente": new_id}

    except Exception as e:
        print("Error in paciente_service.create:", e)
        raise Exception("Error al crear paciente")

def update(id, data: PatientUpdate):
    
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.callproc("sp_actualizar_paciente_ctx", [
            id,
            data.tipo_documento,
            data.documento,
            data.nombre_completo,
            data.fecha_ingreso,
            data.id_usuario
        ])

        connection.commit()

        cursor.close()
        connection.close()

        return {
            "message": "Paciente actualizado correctamente",
            "id_paciente": id
        }

    except Exception as e:
        print("Error in paciente_service.update_ctx:", e)
        raise Exception("Error al actualizar el paciente")

def updateLastAttentionDate(id_paciente):
    try:
        connection = get_connection()
        cursor = connection.cursor()
        cursor.callproc("sp_actualizar_ultima_atencion", [id_paciente])
        connection.commit()

        cursor.close()
        connection.close()
        return {"message": "Paciente actualizado"}

    except Exception as e:
        print("Error in paciente_service.update:", e)
        raise Exception("Error al actualizar el paciente")

def updateLastAttentionDateCtx(id_paciente, id_usuario):
    try:
        connection = get_connection()
        cursor = connection.cursor()
        cursor.callproc("sp_actualizar_ultima_atencion", [id_paciente, id_usuario])
        connection.commit()

        cursor.close()
        connection.close()
        return {"message": "Paciente actualizado"}

    except Exception as e:
        print("Error in paciente_service.update:", e)
        raise Exception("Error al actualizar el paciente")


def delete(id_paciente):
    try:
        connection = get_connection()
        cursor = connection.cursor()
        cursor.callproc("sp_eliminar_paciente", [id_paciente])
        connection.commit()

        cursor.close()
        connection.close()
        return {"message": "Paciente eliminado"}

    except Exception as e:
        print("Error in paciente_service.delete:", e)
        raise Exception("Error eliminando paciente")



def delete_ctx(id_paciente, id_usuario):
    try:
        connection = get_connection()
        cursor = connection.cursor()
        cursor.callproc("sp_eliminar_paciente", [id_paciente, id_usuario])
        connection.commit()

        cursor.close()
        connection.close()
        return {"message": "Paciente eliminado"}

    except Exception as e:
        print("Error in paciente_service.delete:", e)
        raise Exception("Error eliminando paciente")


def get_by_id(id):
    
    try:
        connection = get_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.callproc("sp_obtener_paciente", [id])

        row = None
        for result in cursor.stored_results():
            row = result.fetchone()

        cursor.close()
        connection.close()

        return Paciente.from_db_row(row).to_dict() if row else None

    except Exception as e:
        print("Error in paciente_service.get_by_id:", e)
        raise Exception("Error buscando paciente")
