# -*- coding: utf-8 -*-
# scraper.py

import requests # httpxの代わりにrequestsをインポート
from bs4 import BeautifulSoup
from typing import List
import logging

from models import Article

# ロガーを設定
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG) # デバッグレベルのログも出力

def scrape_programming_news() -> List[Article]: # asyncを削除
    """
    Zenn.devの最新記事から記事を10件スクレイピングします。
    """
    logger.debug("scrape_programming_news called (synchronous test).")
    url = "https://zenn.dev/articles"
    articles = []
    try:
        logger.debug("Before requests.get()...")
        response = requests.get(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}, timeout=30.0)
        logger.debug(f"Response status code: {response.status_code}")
        response.raise_for_status()
        logger.debug("After requests.get() and response.raise_for_status()...")
        logger.debug(f"Response text snippet: {response.text[:200]}")

        soup = BeautifulSoup(response.text, 'html.parser')
        logger.debug("After BeautifulSoup parsing...")

        article_containers = soup.select('div[class*="ArticleList_container"]')
        logger.debug(f"Found {len(article_containers)} article containers.")
        
        for i, container in enumerate(article_containers[:10]):
            logger.debug(f"Processing container {i+1}...")
            title = None
            full_url = None
            summary = None
            thumbnail_url = None

            title_link_element = container.select_one('h2 a, h3 a')
            if title_link_element and title_link_element.has_attr('href'):
                title = title_link_element.get_text(strip=True)
                full_url = f"https://zenn.dev{title_link_element['href']}"

            summary_element = container.select_one('p[class*="ArticleList_desc"]')
            if summary_element:
                summary = summary_element.get_text(strip=True)

            thumbnail_element = container.select_one('img[src*="res.cloudinary.com/zenn/image/upload/"]')
            if thumbnail_element and thumbnail_element.has_attr('src'):
                thumbnail_url = thumbnail_element['src']

            if title and full_url:
                article = Article(
                    title=title,
                    url=full_url,
                    published_date=None,
                    summary=summary,
                    thumbnail_url=thumbnail_url,
                    sentiment='neutral'
                )
                articles.append(article)
                logger.debug(f"Added article: {title}")
            else:
                logger.debug(f"Skipping container {i+1}: Missing title or URL.")

    except requests.exceptions.RequestException as e: # requestsの例外をキャッチ
        logger.error(f"[ERROR] An error occurred while requesting {url!r}: {e}")
        return []
    except Exception as e:
        logger.error(f"[ERROR] An unexpected error occurred: {e}")
        return []

    return articles
