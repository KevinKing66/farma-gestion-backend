import  mysql.connector
from src.config.setting import settings


USER = "farmagestion_user"
PASSWORD = "password123"
DB_NAME = "farmagestion"
PORT = 3306
DATABASE_URL = f"mysql+mysqlconnector://{USER}:{PASSWORD}@localhost:{PORT}/{DB_NAME}"


import mysql.connector

def get_connection():
    connection = mysql.connector.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD,
        database=settings.DATABASE_NAME,
        charset='utf8mb4',
        collation='utf8mb4_unicode_ci'
    )
    return connection


# engine = create_engine(DATABASE_URL)
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependencia para inyección
# def get_connection():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()

# def test_connection():
#     try:
#         with engine.connect() as connection:
#             result = connection.execute(text("SELECT 1"))
#             print("Conexión exitosa a la base de datos.")
#     except Exception as e:
#         print("Error al conectar a la base de datos:", e)

# test_connection()