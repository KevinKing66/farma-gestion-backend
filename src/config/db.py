from asyncmy import pool
from contextlib import asynccontextmanager
from fastapi import FastAPI
from src.config.setting import settings
from asyncmy.connection import Connection

db_pool: pool.Pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_pool
    print("Inicializando Pool de Conexiones a MySQL...")
    db_pool = await pool.create_pool(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD,
        db=settings.DATABASE_NAME,
        autocommit=True,
        minsize=1, maxsize=10
    )
    print("Pool de Conexiones a MySQL inicializado.")
    yield
    print("Cerrando Pool de Conexiones a MySQL...")
    await db_pool.close()
    print("Pool de Conexiones cerrado.")

# Inyector de Dependencia
async def get_db_connection():
    """Provee una conexión de la DB a través del pool."""
    global db_pool
    if db_pool is None:
        # Esto no debería ocurrir si lifespan se usa correctamente, pero es una protección.
        raise RuntimeError("El pool de conexiones no ha sido inicializado.")
        
    async with db_pool.acquire() as connection:
        yield connection