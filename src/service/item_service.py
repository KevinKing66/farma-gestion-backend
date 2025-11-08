from typing import Any, Dict, List, Optional, cast
from src.schemas.item_schema import ItemResponse
from src.models.item_model import Item
from src.config.database import get_connection


def get_all_items() -> List[ItemResponse]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT i.*, u.nombre AS nombre_ubicacion
        FROM items i
        INNER JOIN ubicaciones u ON i.id_ubicacion = u.id_ubicacion
    """)
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return [ItemResponse(**cast(Dict[str, Any], row)) for row in rows]


def get_item_by_id(id_item: int) -> Optional[Item]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT i.*, u.nombre AS nombre_ubicacion
        FROM items i
        INNER JOIN ubicaciones u ON i.id_ubicacion = u.id_ubicacion
        WHERE i.id_item = %s
    """, (id_item,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return Item(**cast(Dict[str, Any], result)) if result else None


def create_item(id_ubicacion: int, codigo: str, descripcion: str, tipo_item: str, unidad_medida: str, stock_minimo: int):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "CALL sp_crear_item(%s, %s, %s, %s, %s, %s)",
        (id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo)
    )
    conn.commit()
    cursor.close()
    conn.close()


def update_item(id_item: int, id_ubicacion: int, codigo: str, descripcion: str, tipo_item: str, unidad_medida: str, stock_minimo: int):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "CALL sp_actualizar_item(%s, %s, %s, %s, %s, %s, %s)",
        (id_item, id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo)
    )
    conn.commit()
    cursor.close()
    conn.close()


def delete_item(id_item: int):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("CALL sp_eliminar_item(%s)", (id_item,))
    conn.commit()
    cursor.close()
    conn.close()


def update_location(id_item: int, id_location: int) -> Optional[ItemResponse]:
    current = get_item_by_id(id_item)
    if current is None:
        raise Exception("Item no encontrado")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    params: tuple[Any, ...] = (
        id_item,
        id_location,
        current.codigo,
        current.descripcion,
        current.tipo_item,
        current.unidad_medida,
        current.stock_minimo,
    )

    cursor.execute("CALL sp_actualizar_items(%s, %s, %s, %s, %s, %s, %s)", params)
    result = cursor.fetchone()
    cursor.close()
    conn.close()

    return ItemResponse(**cast(Dict[str, Any], result)) if result else None
