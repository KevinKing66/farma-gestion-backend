from typing import Any, Dict, List, Optional, cast
from src.schemas.stg_inventario_inicial_schema import (
    StgInventarioInicialSchema,
    StgInventarioInicialResponse,
)
from src.config.database import get_connection

def create(data: StgInventarioInicialSchema) -> None:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        CALL sp_crear_stg_inventario_inicial(%s, %s, %s, %s, %s, %s, %s)
        """,
        (
            data.codigo_item,
            data.nit_proveedor,
            data.codigo_lote,
            data.fecha_vencimiento,
            data.costo_unitario,
            data.nombre_ubicacion,
            data.cantidad,
        ),
    )
    conn.commit()
    cursor.close()
    conn.close()

def getByItemAndLote(
    codigo_item: str, codigo_lote: str
) -> Optional[StgInventarioInicialResponse]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        CALL sp_obtener_stg_inventario_inicial(%s, %s)
        """,
        (codigo_item, codigo_lote),
    )
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return (
        StgInventarioInicialResponse(**cast(Dict[str, Any], result))
        if result
        else None
    )

def get_all() -> List[StgInventarioInicialResponse]:
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("CALL sp_listar_stg_inventario_inicial()")
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    return [
        StgInventarioInicialResponse(**cast(Dict[str, Any], r))
        for r in results
    ]

def update(data: StgInventarioInicialSchema) -> None:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        CALL sp_actualizar_stg_inventario_inicial(%s, %s, %s, %s, %s, %s)
        """,
        (
            data.codigo_item,
            data.codigo_lote,
            data.fecha_vencimiento,
            data.costo_unitario,
            data.nombre_ubicacion,
            data.cantidad,
        ),
    )
    conn.commit()
    cursor.close()
    conn.close()

def delete(codigo_item: str, codigo_lote: str) -> None:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        CALL sp_eliminar_stg_inventario_inicial(%s, %s)
        """,
        (codigo_item, codigo_lote),
    )
    conn.commit()
    cursor.close()
    conn.close()
