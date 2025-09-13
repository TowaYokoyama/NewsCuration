# backend/api/articles.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import logging
import asyncio
import requests

import crud
import schemas
import db_models as models
from core.db import get_db
from core.security import get_current_user
# Add the recommender import
from core import recommender

router = APIRouter()
logger = logging.getLogger(__name__)

# --- Data Fetching Logic (Copied from main.py) ---
async def get_articles_for_category(category: str) -> List[schemas.Article]:
    """
    カテゴリに基づいて、適切なソースから記事を取得するディスパッチャ関数。
    """
    logger.info(f"Fetching articles for category: {category}")
    
    if category == "programming":
        # This is a debug section and should be replaced with actual scraping
        return [
            schemas.Article(
                id=999, # Dummy ID
                title="DEBUG: Direct Requests Test Article",
                url="https://debug.example.com/direct-requests",
                summary="This article is returned from a direct requests.get() call in api/articles.py.",
                sentiment="neutral"
            )
        ]
    
    # 他のかてごりは、引き続きダミーデータを返す
    await asyncio.sleep(0.5)  # 非同期処理のシミュレーション

    gamba_article = schemas.Article(
        id=1,
        title="ガンバ大阪、週末の試合で劇的勝利！",
        url="https://example.com/gamba-win",
        published_date="2025-09-06",
        summary="宇佐美選手の決勝ゴールで、ガンバ大阪が勝利を収めました。",
        thumbnail_url="https://example.com/images/gamba.jpg",
        sentiment="positive"
    )

    soccer_article = schemas.Article(
        id=2,
        title="海外サッカー、日本人選手の活躍まとめ",
        url="https://example.com/soccer-japan",
        published_date="2025-09-06",
        summary="今週の海外リーグで活躍した日本人選手のゴールやアシストを振り返ります。",
        thumbnail_url="https://example.com/images/soccer.jpg",
        sentiment="neutral"
    )

    coffee_article = schemas.Article(
        id=3,
        title="新しいコーヒー豆の選び方",
        url="https://example.com/coffee-beans",
        published_date="2025-09-05",
        summary="専門家が教える、自宅で美味しいコーヒーを楽しむための豆選びのコツ。",
        thumbnail_url="https://example.com/images/coffee.jpg",
        sentiment="neutral"
    )

    if category == "gamba_osaka":
        return [gamba_article]
    elif category == "soccer":
        return [soccer_article]
    elif category == "coffee":
        return [coffee_article]
    else:
        return [] # 不明なカテゴリの場合は空のリストを返す

@router.get("/{category}", response_model=List[schemas.Article])
async def get_articles(category: str, current_user: models.User = Depends(get_current_user)):
    """
    指定されたカテゴリの記事を取得します。
    
    - **category**: 記事のカテゴリ (`gamba_osaka`, `soccer`, `coffee`, `programming`)
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
    # Check if already favorited to avoid duplicates, although the relationship should handle it.
    if article in current_user.favorite_articles:
        return current_user # Or raise a 400 error
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
