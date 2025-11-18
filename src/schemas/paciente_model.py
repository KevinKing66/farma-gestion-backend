from pydantic import BaseModel
from typing import Optional

class PatientCreate(BaseModel):
    tipo_documento: str
    documento: str
    nombre_completo: str
    fecha_ingreso: Optional[str] = None  # YYYY-MM-DD


class PatientResponse(BaseModel):
    id_paciente: int
    tipo_documento: Optional[str]
    documento: str
    nombre_completo: str
    fecha_ingreso: Optional[str]
    ultima_atencion: Optional[str]


class PatientUpdateLastCare(BaseModel):
    id_paciente: int
