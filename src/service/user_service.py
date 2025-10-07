from asyncmy.connection import Connection
from typing import List, Optional
import bcrypt
from src.schemas.user import UserCreate, UserUpdate, UserPublic, UserInDB

def hash_pssword(password: str) -> str:
    password_bytes = password.encode('utf-8')
    hashed_bytes = bcrypt.hashpw(password_bytes, bcrypt.gensalt(rounds=12))
    return hashed_bytes.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        plain_password_bytes = plain_password.encode('utf-8')
        hashed_password_bytes = hashed_password.encode('utf-8')
        
        return bcrypt.checkpw(plain_password_bytes, hashed_password_bytes)
    except ValueError:
        return False

async def get_users(conn: Connection) -> List[UserPublic]:
    """Recupera todos los usuarios."""
    query = "SELECT id, username, email FROM users;"
    async with conn.cursor(conn.dict_cursor) as cursor:
        await cursor.execute(query)
        rows = await cursor.fetchall()
        # Mapeamos los resultados a UserPublic (sin password_hash)
        return [UserPublic(**row) for row in rows]

async def get_user(conn: Connection, user_id: int) -> Optional[UserPublic]:
    """Recupera un usuario por ID para respuesta pública."""
    query = "SELECT id, username, email FROM users WHERE id = %s;"
    async with conn.cursor(conn.dict_cursor) as cursor:
        await cursor.execute(query, (user_id,))
        row = await cursor.fetchone()
        return UserPublic(**row) if row else None
    
async def create_user(conn: Connection, user: UserCreate) -> UserPublic | None:
    """Crea un nuevo usuario y devuelve el objeto público."""
    hashed_password = hash_pssword(user.password)
    
    query = "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s);"
    params = (user.fullname, user.email, hashed_password)
    
    async with conn.cursor() as cursor:
        await cursor.execute(query, params)
        await conn.commit()
        last_id = cursor.lastrowid
        
        # Recuperamos y retornamos el usuario recién creado
        return await get_user(conn, last_id)


async def get_user_by_username(conn: Connection, username: str) -> Optional[UserInDB]:
    """Recupera un usuario por nombre de usuario (incluyendo hash para validación)."""
    query = "SELECT id, username, email, password_hash FROM users WHERE username = %s;"
    async with conn.cursor(conn.dict_cursor) as cursor:
        await cursor.execute(query, (username,))
        row = await cursor.fetchone()
        return UserInDB(**row) if row else None

async def update_user(conn: Connection, user_id: int, user: UserUpdate) -> Optional[UserPublic]:
    """Actualiza un usuario existente."""
    
    # 1. Construir la consulta de forma dinámica
    fields = []
    params = []
    
    if user.username:
        fields.append("username = %s")
        params.append(user.username)
    if user.email:
        fields.append("email = %s")
        params.append(user.email)
    if user.password:
        hashed_password = hash_pssword(user.password)
        fields.append("password_hash = %s")
        params.append(hashed_password)

    if not fields:
        # No hay nada que actualizar
        return await get_user(conn, user_id)

    query = f"UPDATE users SET {', '.join(fields)} WHERE id = %s;"
    params.append(user_id)
    
    # 2. Ejecutar la actualización
    async with conn.cursor() as cursor:
        await cursor.execute(query, tuple(params))
        await conn.commit()
        
        # 3. Devolver el usuario actualizado o None si no se encontró
        if cursor.rowcount > 0:
            return await get_user(conn, user_id)
        return None

async def delete_user(conn: Connection, user_id: int) -> bool:
    """Elimina un usuario por ID."""
    query = "DELETE FROM users WHERE id = %s;"
    async with conn.cursor() as cursor:
        await cursor.execute(query, (user_id,))
        await conn.commit()
        return cursor.rowcount > 0