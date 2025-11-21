from typing import Any


class Item:
    def __init__(self, id_item: int, id_ubicacion: int, codigo: str, descripcion: str, tipo_item: str, unidad_medida: str, stock_minimo: int, uso_frecuente: Any | None = None):
        self.id_item = id_item
        self.id_ubicacion = id_ubicacion
        self.codigo = codigo
        self.descripcion = descripcion
        self.tipo_item = tipo_item
        self.unidad_medida = unidad_medida
        self.stock_minimo = stock_minimo
        self.uso_frecuente = uso_frecuente
