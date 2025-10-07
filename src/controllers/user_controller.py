from sqlalchemy.orm import Session
from src.models.user import User
from src.schemas.user import UserCreate

def create_user(db: Session, user: UserCreate):
    new_user = User(nombre_completo=user.fullname, correo=user.email, contrasena=user.password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

def get_users(db: Session):
    return db.query(User).all()
