# farma-gestion-backend
Este es el backend del proyecto farma gestion, el cual está dirigido a solucionar una necesidad del hospital de Timbio, Cauca

## instalar dependencias
`pip install -r requirements.txt`

## generar modelos de entidades basados en las tablas de la db
`sqlacodegen mysql+mysqlconnector://farmagestion_user:password123@localhost:3306/farmagestion > app/models/models.py`

## correr aplicacion
`python -m uvicorn main:app --reload`