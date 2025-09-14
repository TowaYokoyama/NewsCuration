# backend/api/articles.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import logging
import asyncio
import random

import crud
import schemas
import db_models as models
from core.db import get_db
from core.security import get_current_user
from core import recommender
from scraper import get_rakuten_recipes, scrape_zenn_news, scrape_qiita_news

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/{category_id}", response_model=List[schemas.Article])
async def get_articles(category_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """
    指定されたカテゴリIDに基づいて記事やレシピを取得します。
    - "programming" のような特別なカテゴリ名も受け付けます。
    - それ以外は楽天のカテゴリID（例: "27-266"）として扱います。
    """
    logger.info(f"User: {current_user.email}, Category ID: {category_id}")

    if category_id == "programming":
        # Scrape new articles
        zenn_task = scrape_zenn_news()
        qiita_task = scrape_qiita_news()
        scraped_results = await asyncio.gather(zenn_task, qiita_task)
        
        # Save new articles to the database
        for article_model in scraped_results[0] + scraped_results[1]:
            db_article = crud.get_article_by_url(db, url=article_model.url)
            if not db_article:
                article_schema = schemas.ArticleCreate(**article_model.model_dump())
                crud.create_article(db, article=article_schema)
        
        # Ensure the database doesn't grow too large
        crud.cull_old_articles(db, max_count=200)

        # Fetch all programming articles from the DB and return a random sample
        all_db_articles = crud.get_all_articles(db)
        sample_size = min(15, len(all_db_articles))
        return random.sample(all_db_articles, sample_size)
    
    else:
        # Assume it's a Rakuten category ID
        rakuten_recipes = await get_rakuten_recipes(category_id)
        # Note: These are not saved to the database
        return [
            schemas.Article(
                id=30000 + i, # Dummy ID
                title=recipe.title,
                url=recipe.url,
                published_date=recipe.published_date,
                summary=recipe.summary,
                thumbnail_url=recipe.thumbnail_url,
                sentiment=recipe.sentiment,
            )
            for i, recipe in enumerate(rakuten_recipes)
        ]

# The rest of the file remains the same for favorites and recommendations

@router.get("/me/recommendations", response_model=List[schemas.Article])
def get_recommendations(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """
    Get personalized article recommendations for the current user.
    """
    recommended_articles = recommender.generate_recommendations(db=db, user=current_user)
    return recommended_articles

@router.post("/{article_id}/favorite", response_model=schemas.User)
def add_favorite(article_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    article = crud.get_article(db, article_id=article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    if article in current_user.favorite_articles:
        return current_user
    return crud.favorite_article(db=db, user=current_user, article=article)

@router.delete("/{article_id}/favorite", response_model=schemas.User)
def remove_favorite(article_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    article = crud.get_article(db, article_id=article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    if article not in current_user.favorite_articles:
        raise HTTPException(status_code=404, detail="Article not in favorites")
    return crud.unfavorite_article(db=db, user=current_user, article=article)

@router.get("/me/favorites", response_model=List[schemas.Article])
def read_favorites(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return crud.get_favorite_articles(db=db, user=current_user)
