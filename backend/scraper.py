# -*- coding: utf-8 -*-
# scraper.py

import httpx
from bs4 import BeautifulSoup
import json
from typing import List
import logging
import feedparser
import asyncio

from models import Article, RecipeCategory
from core.config import settings

# ロガーを設定
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

async def get_rakuten_recipes(category_id: str) -> List[Article]:
    """
    楽天レシピカテゴリ別ランキングAPIからレシピ情報を取得します。
    """
    logger.debug(f"get_rakuten_recipes called for category_id: {category_id}")
    app_id = "1063462595265589229" # Using user-provided ID for this session

    url = f"https://app.rakuten.co.jp/services/api/Recipe/CategoryRanking/20170426?applicationId={app_id}&categoryId={category_id}"
    articles = []
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, timeout=10.0)
            response.raise_for_status()
            data = response.json()

        logger.debug(f"Successfully fetched {len(data['result'])} recipes from Rakuten API.")

        for item in data['result']:
            article = Article(
                title=item.get('recipeTitle', 'No Title'),
                url=item.get('recipeUrl'),
                published_date=item.get('updateTime'),
                summary=item.get('recipeDescription'),
                thumbnail_url=item.get('foodImageUrl'),
                sentiment='neutral'
            )
            articles.append(article)

    except Exception as e:
        logger.error(f"[ERROR] An error occurred during Rakuten API call: {e}")
        return []

    return articles

async def scrape_zenn_news() -> List[Article]:
    """
    Zenn.devの最新記事を非同期でスクレイピングします。
    """
    logger.debug("scrape_zenn_news called.")
    url = "https://zenn.dev/articles"
    articles = []
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=10.0)
            response.raise_for_status()

        soup = BeautifulSoup(response.text, 'html.parser')
        next_data_script = soup.find('script', {'id': '__NEXT_DATA__'})
        if not next_data_script:
            logger.error("Could not find __NEXT_DATA__ script tag on Zenn.")
            return []

        json_data = json.loads(next_data_script.string)
        page_articles = json_data.get('props', {}).get('pageProps', {}).get('articles', [])
        logger.debug(f"Found {len(page_articles)} articles in Zenn JSON data.")

        for item in page_articles:
            article = Article(
                title=item.get('title', 'No Title'),
                url=f"https://zenn.dev{item.get('path')}",
                published_date=item.get('publishedAt'),
                summary=None,
                thumbnail_url=item.get('user', {}).get('avatarSmallUrl'),
                sentiment='neutral'
            )
            articles.append(article)

    except Exception as e:
        logger.error(f"[ERROR] An error occurred during Zenn scraping: {e}")
        return []

    return articles

async def scrape_qiita_news() -> List[Article]:
    """
    Qiita.comのトレンド記事を非同期でスクレイピングします。
    """
    logger.debug("scrape_qiita_news called.")
    url = "https://qiita.com/"
    articles = []
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=10.0)
            response.raise_for_status()

        soup = BeautifulSoup(response.text, 'html.parser')
        trend_script = soup.find('script', {'data-component-name': 'HomeTrendPage'})
        if not trend_script:
            logger.error("Could not find HomeTrendPage component script tag on Qiita.")
            return []

        json_data = json.loads(trend_script.string)
        trend_edges = json_data.get('trend', {}).get('edges', [])
        logger.debug(f"Found {len(trend_edges)} articles in Qiita JSON data.")

        for edge in trend_edges:
            node = edge.get('node', {})
            if not node:
                continue

            article = Article(
                title=node.get('title', 'No Title'),
                url=node.get('linkUrl'),
                published_date=node.get('createdAt'),
                summary=None,
                thumbnail_url=node.get('author', {}).get('profileImageUrl'),
                sentiment='neutral'
            )
            articles.append(article)

    except Exception as e:
        logger.error(f"[ERROR] An error occurred during Qiita scraping: {e}")
        return []

    return articles

async def get_rakuten_categories(parent_category_id: str) -> List[RecipeCategory]:
    """
    楽天レシピカテゴリ一覧APIから指定された親カテゴリに属する中カテゴリを取得します。
    """
    logger.debug(f"get_rakuten_categories called for parent_category_id: {parent_category_id}")
    app_id = "1063462595265589229" # Using user-provided ID for this session
    url = f"https://app.rakuten.co.jp/services/api/Recipe/CategoryList/20170426?applicationId={app_id}"
    categories = []
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, timeout=10.0)
            response.raise_for_status()
            data = response.json()

        medium_categories = data.get('result', {}).get('medium', [])
        
        # 親カテゴリIDに一致するものをフィルタリング
        for cat in medium_categories:
            if cat.get('parentCategoryId') == parent_category_id:
                # Construct the full category ID string (e.g., "27-266")
                full_category_id = f"{parent_category_id}-{cat['categoryId']}"
                categories.append(
                    RecipeCategory(categoryId=full_category_id, categoryName=cat['categoryName'])
                )
        
        logger.debug(f"Found {len(categories)} sub-categories for parent {parent_category_id}.")

    except Exception as e:
        logger.error(f"[ERROR] An error occurred during Rakuten Category List API call: {e}")
        return []

    return categories