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

def get_article_by_url(db: Session, url: str):
    return db.query(models.Article).filter(models.Article.url == url).first()

def get_all_articles(db: Session, skip: int = 0, limit: int = 1000):
    return db.query(models.Article).order_by(models.Article.published_date.desc()).offset(skip).limit(limit).all()

def create_article(db: Session, article: schemas.ArticleCreate) -> models.Article:
    db_article = models.Article(**article.model_dump())
    db.add(db_article)
    db.commit()
    db.refresh(db_article)
    return db_article

def cull_old_articles(db: Session, max_count: int = 200):
    """
    Keeps the number of articles at max_count by deleting the oldest ones.
    """
    article_count = db.query(models.Article).count()
    if article_count > max_count:
        num_to_delete = article_count - max_count
        oldest_articles = db.query(models.Article).order_by(models.Article.published_date.asc()).limit(num_to_delete).all()
        for article in oldest_articles:
            db.delete(article)
        db.commit()

# --- Favorite CRUD ---
def favorite_article(db: Session, user: models.User, article: models.Article):
    if article not in user.favorite_articles:
        user.favorite_articles.append(article)
        db.commit()
    return user

def unfavorite_article(db: Session, user: models.User, article: models.Article):
    if article in user.favorite_articles:
        user.favorite_articles.remove(article)
        db.commit()
    return user

def get_favorite_articles(db: Session, user: models.User):
    return user.favorite_articles

