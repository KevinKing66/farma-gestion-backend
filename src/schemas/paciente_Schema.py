from datetime import date
from pydantic import BaseModel
from typing import Optional
from enum import Enum

class DocumentType(str, Enum):
    CEDULA = "CEDULA"
    TARJETA_IDENTIDAD = "TARJETA DE IDENTIDAD"
    TARJETA_EXTRANJERIA = "TARJETA DE EXTRANJERÍA"

class PatientCreate(BaseModel):
    tipo_documento: str
    documento: str
    nombre_completo: str
    fecha_ingreso: Optional[str] = None  # YYYY-MM-DD
    id_usuario: int


class PatientResponse(BaseModel):
    id_paciente: int
    tipo_documento: Optional[str]
    documento: str
    nombre_completo: str
    fecha_ingreso: Optional[str]
    ultima_atencion: Optional[str]


class PatientUpdateLastCare(BaseModel):
    id_paciente: int

class PatientUpdate(BaseModel):
    tipo_documento: DocumentType
    documento: str
    nombre_completo: str
    fecha_ingreso: Optional[date] = None
    id_usuario: int