from src.service import inventario_service
def find_all():
    try:
        return inventario_service.find_all_inventario()
    except Exception as e:
        return {"error": str(e)}

def find_all_inventario_by_keyword_and_pagination(filter: str, pages: int = 0, elementPerPages: int = 10):
    try:
        return inventario_service.find_all_inventario_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)
    except Exception as e:
        return {"error": str(e)}


def find_all_medicamento_by_keyword_and_pagination(filter: str, pages: int = 0, elementPerPages: int = 10):
    try:
        return inventario_service.find_all_medicamento_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)
    except Exception as e:
        return {"error": str(e)}
