# backend/schemas.py
#APIでデータをやり取りする際の型定義
from pydantic import BaseModel, ConfigDict
from typing import Optional, List

# --- Token Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# --- Article Schemas ---
class ArticleBase(BaseModel):
    title: str
    url: str
    published_date: Optional[str] = None
    summary: Optional[str] = None
    thumbnail_url: Optional[str] = None
    sentiment: Optional[str] = "neutral"

class ArticleCreate(ArticleBase):
    pass

class Article(ArticleBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

# --- User Schemas ---
class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    favorite_articles: List[Article] = []
    model_config = ConfigDict(from_attributes=True)
