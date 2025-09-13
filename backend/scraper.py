# -*- coding: utf-8 -*-
# scraper.py

import httpx
from bs4 import BeautifulSoup
import json
from typing import List
import logging
import feedparser
import asyncio

from models import Article

# ロガーを設定
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

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

async def scrape_soccer_news() -> List[Article]:
    """
    ゲキサカのRSSフィードからサッカーニュースを非同期で取得します。
    """
    logger.debug("scrape_soccer_news called.")
    url = "https://web.gekisaka.jp/pickup/news/category?menu=new&rss=true"
    articles = []
    try:
        # feedparser is synchronous, run it in a thread to avoid blocking asyncio loop
        loop = asyncio.get_event_loop()
        feed = await loop.run_in_executor(None, feedparser.parse, url)
        
        logger.debug(f"Found {len(feed.entries)} articles in Gekisaka RSS feed.")

        for entry in feed.entries:
            thumbnail_url = None
            if 'media_thumbnail' in entry and entry.media_thumbnail:
                thumbnail_url = entry.media_thumbnail[0].get('url')

            article = Article(
                title=entry.title,
                url=entry.link,
                published_date=entry.get('published'),
                summary=entry.get('summary'),
                thumbnail_url=thumbnail_url,
                sentiment='neutral'
            )
            articles.append(article)

    except Exception as e:
        logger.error(f"[ERROR] An error occurred during Gekisaka RSS fetching: {e}")
        return []

    return articles