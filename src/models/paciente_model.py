from typing import Optional


class Paciente:
    def __init__(
        self,
        id_paciente: int,
        tipo_documento: Optional[str],
        documento: str,
        nombre_completo: str,
        fecha_ingreso: Optional[str] = None,
        ultima_atencion: Optional[str] = None
    ):
        self.id_paciente = id_paciente
        self.tipo_documento = tipo_documento
        self.documento = documento
        self.nombre_completo = nombre_completo
        self.fecha_ingreso = fecha_ingreso
        self.ultima_atencion = ultima_atencion

    def to_dict(self):
        return {
            "id_paciente": self.id_paciente,
            "tipo_documento": self.tipo_documento,
            "documento": self.documento,
            "nombre_completo": self.nombre_completo,
            "fecha_ingreso": self.fecha_ingreso,
            "ultima_atencion": self.ultima_atencion
        }

    @staticmethod
    def from_db_row(row: dict):
        """
        Convierte una fila del cursor (dictionary=True) en un objeto Paciente
        """
        return Paciente(
            id_paciente=row.get("id_paciente"),
            tipo_documento=row.get("tipo_documento"),
            documento=row.get("documento"),
            nombre_completo=row.get("nombre_completo") or row.get("nombre"),
            fecha_ingreso=row.get("fecha_ingreso"),
            ultima_atencion=row.get("ultima_atencion")
        )
