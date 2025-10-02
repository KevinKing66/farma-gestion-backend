from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

USER = "farmagestion_user"
PASSWORD = "password123"
DB_NAME = "farmagestion"
PORT = 3306
DATABASE_URL = f"mysql+mysqlconnector://{USER}:{PASSWORD}@localhost:{PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependencia para inyección
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def test_connection():
    try:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT 1"))
            print("Conexión exitosa a la base de datos.")
    except Exception as e:
        print("Error al conectar a la base de datos:", e)

test_connection()