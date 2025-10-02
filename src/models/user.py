from sqlalchemy import Column, Integer, String
from src.config.database import Base

class User(Base):
    __tablename__ = "users"

    id_usuario = Column(Integer, primary_key=True, index=True)
    nombre_completo = Column(String(128), nullable=False)
    correo = Column(String(128), unique=True, index=True, nullable=False)
    rol = Column(String(16), nullable=False)
    contrasena = Column(String(2048), nullable=False)
