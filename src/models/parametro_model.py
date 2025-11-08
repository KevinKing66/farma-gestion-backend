from pydantic import BaseModel
from typing import Optional


class Parametro(BaseModel):
    clave: str
    valor: str
    descripcion: Optional[str]
