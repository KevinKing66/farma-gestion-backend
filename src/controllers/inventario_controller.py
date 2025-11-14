from src.service import inventario_service
def get_all():
    try:
        return inventario_service.find_all_inventario()
    except Exception as e:
        return {"error": str(e)}

def get_inventario_by_keyword_and_pagination(filter: str, pages: int = 0, elementPerPages: int = 10):
    try:
        return inventario_service.get_inventario_by_keyword_and_pagination(filter=filter, pages=pages, elementPerPages=elementPerPages)
    except Exception as e:
        return {"error": str(e)}
