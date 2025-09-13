# backend/db_models.py
from sqlalchemy import Column, Integer, String, Text, ForeignKey, Table, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from core.db import Base

# Association table for User and Article (Favorites)
favorite_table = Table('favorites',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('article_id', Integer, ForeignKey('articles.id'), primary_key=True),
    Column('created_at', DateTime(timezone=True), server_default=func.now())
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    favorite_articles = relationship("Article", secondary=favorite_table, back_populates="favorited_by")

class Article(Base):
    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    url = Column(String, nullable=False, unique=True, index=True)
    published_date = Column(String)
    summary = Column(Text)
    thumbnail_url = Column(String)
    sentiment = Column(String, default="neutral")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    favorited_by = relationship("User", secondary=favorite_table, back_populates="favorite_articles")
