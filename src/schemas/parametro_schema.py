from pydantic import BaseModel, Field
from typing import Optional


class ParametroBase(BaseModel):
    valor: str = Field(..., max_length=100)
    descripcion: Optional[str] = Field(None, max_length=255)


class ParametroCreate(ParametroBase):
    clave: str = Field(..., max_length=50)


class ParametroUpdate(ParametroBase):
    pass


class ParametroResponse(ParametroBase):
    clave: str
