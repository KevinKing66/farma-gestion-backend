from fastapi import FastAPI
from src.config.database import engine
from src.config.base import Base
from src.routes import user_routes

Base.metadata.create_all(bind=engine)

app = FastAPI(title="FastAPI MVC MySQL")

app.include_router(user_routes.router)
