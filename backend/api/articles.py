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

# Map frontend category names to Rakuten Recipe Category IDs
RAKUTEN_CATEGORY_MAP = {
    "coffee": "27-266",
    "cooking": "30", # "Popular Menu"
}

async def get_articles_for_category(category: str) -> List[schemas.Article]:
    """
    カテゴリに基づいて、適切なソースから記事を取得するディスパッチャ関数。
    """
    logger.info(f"Fetching articles for category: {category}")
    
    if category == "programming":
        zenn_task = scrape_zenn_news()
        qiita_task = scrape_qiita_news()
        results = await asyncio.gather(zenn_task, qiita_task)
        all_articles = results[0] + results[1]
        logger.info(f"Total programming articles scraped: {len(all_articles)}")
        if not all_articles:
            return []
        sample_size = min(15, len(all_articles))
        sampled_articles = random.sample(all_articles, sample_size)
        return [
            schemas.Article(
                id=10000 + i,
                title=article.title,
                url=article.url,
                published_date=article.published_date,
                summary=article.summary,
                thumbnail_url=article.thumbnail_url,
                sentiment=article.sentiment,
            )
            for i, article in enumerate(sampled_articles)
        ]

    elif category in RAKUTEN_CATEGORY_MAP:
        category_id = RAKUTEN_CATEGORY_MAP[category]
        rakuten_recipes = await get_rakuten_recipes(category_id)
        return [
            schemas.Article(
                id=30000 + i,
                title=recipe.title,
                url=recipe.url,
                published_date=recipe.published_date,
                summary=recipe.summary,
                thumbnail_url=recipe.thumbnail_url,
                sentiment=recipe.sentiment,
            )
            for i, recipe in enumerate(rakuten_recipes)
        ]

    else:
        return []

@router.get("/{category}", response_model=List[schemas.Article])
async def get_articles(category: str, current_user: models.User = Depends(get_current_user)):
    """
    指定されたカテゴリの記事を取得します。
    
    - **category**: 記事のカテゴリ (`coffee`, `cooking`, `programming`)
    """
    logger.info(f"User: {current_user.email}, Category: {category}")
    articles = await get_articles_for_category(category)
    return articles

# New endpoint
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