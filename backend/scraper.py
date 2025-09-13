# -*- coding: utf-8 -*-
# scraper.py

import requests
from bs4 import BeautifulSoup
import json
from typing import List
import logging

from models import Article

# ロガーを設定
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

def scrape_programming_news() -> List[Article]:
    """
    Zenn.devの最新記事をスクレイピングします。
    Next.jsのページから__NEXT_DATA__のJSONをパースする方式に変更。
    """
    logger.debug("scrape_programming_news called (JSON parsing method).")
    url = "https://zenn.dev/articles"
    articles = []
    try:
        response = requests.get(url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=10.0)
        response.raise_for_status()

        soup = BeautifulSoup(response.text, 'html.parser')
        
        # __NEXT_DATA__ script tagを見つける
        next_data_script = soup.find('script', {'id': '__NEXT_DATA__'})
        if not next_data_script:
            logger.error("Could not find __NEXT_DATA__ script tag.")
            return []

        # JSONデータをパース
        json_data = json.loads(next_data_script.string)
        
        # JSON構造を辿って記事リストを取得
        # パス: props -> pageProps -> articles
        page_articles = json_data.get('props', {}).get('pageProps', {}).get('articles', [])
        logger.debug(f"Found {len(page_articles)} articles in JSON data.")

        for item in page_articles[:15]: # 15件に制限
            full_url = f"https://zenn.dev{item.get('path')}"
            
            # サムネイル画像のURLを取得 (userオブジェクトから)
            thumbnail_url = item.get('user', {}).get('avatarSmallUrl')

            article = Article(
                title=item.get('title', 'No Title'),
                url=full_url,
                published_date=item.get('publishedAt'),
                summary=None, # JSONデータに概要はないためNone
                thumbnail_url=thumbnail_url,
                sentiment='neutral'
            )
            articles.append(article)
            logger.debug(f"Added article: {article.title}")

    except requests.exceptions.RequestException as e:
        logger.error(f"[ERROR] An error occurred while requesting {url!r}: {e}")
        return []
    except json.JSONDecodeError as e:
        logger.error(f"[ERROR] Failed to parse JSON from __NEXT_DATA__: {e}")
        return []
    except Exception as e:
        logger.error(f"[ERROR] An unexpected error occurred: {e}")
        return []

    return articles