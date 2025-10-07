from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # Configuración de la base de datos MySQL
    DATABASE_HOST: str = "localhost"
    DATABASE_PORT: int = 3306
    DATABASE_USER: str = "farmagestion_user"
    DATABASE_PASSWORD: str = "password123"
    DATABASE_NAME: str = "farmagestion"
    
    DATABASE_URL = f"mysql+mysqlconnector://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"

    # Configuramos el archivo .env para cargar las variables
    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()