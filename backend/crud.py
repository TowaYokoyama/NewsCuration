# backend/crud.py
from sqlalchemy.orm import Session
import db_models as models
import schemas
from core.security import get_password_hash

# --- User CRUD ---
def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = models.User(email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# --- Article CRUD ---
def get_article(db: Session, article_id: int):
    return db.query(models.Article).filter(models.Article.id == article_id).first()

def get_all_articles(db: Session, skip: int = 0, limit: int = 1000):
    return db.query(models.Article).offset(skip).limit(limit).all()

# --- Favorite CRUD ---
def favorite_article(db: Session, user: models.User, article: models.Article):
    user.favorite_articles.append(article)
    db.commit()
    return user

def unfavorite_article(db: Session, user: models.User, article: models.Article):
    user.favorite_articles.remove(article)
    db.commit()
    return user

def get_favorite_articles(db: Session, user: models.User):
    return user.favorite_articles
