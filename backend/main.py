# -*- coding: utf-8 -*-
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import asyncio
import requests # requestsをインポート

# scraper.pyから実際のスクレイピング関数をインポート (一時的にコメントアウト)
# from scraper import scrape_programming_news
# models.pyから共有データモデルをインポート
from models import Article

# ロギング設定
logging.basicConfig(level=logging.DEBUG) # DEBUGレベル以上のログを出力
logger = logging.getLogger(__name__)

# --- FastAPI Application ---
app = FastAPI(
    title="News Curation API",
    description="指定されたサイトから記事を収集し、感情分析（またはキーワード抽出）を行うAPIです。",
    version="0.1.0",
)

# --- CORS Middleware ---
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Data Fetching Logic ---
async def get_articles_for_category(category: str) -> List[Article]:
    """
    カテゴリに基づいて、適切なソースから記事を取得するディスパッチャ関数。
    """
    logger.info(f"Fetching articles for category: {category}")
    
    if category == "programming":
        # デバッグ用: requestsを直接呼び出す
        url = "https://zenn.dev/articles"
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        try:
            logger.debug("Making direct requests.get() call...")
            response = requests.get(url, headers=headers, timeout=30.0)
            logger.debug(f"Direct requests.get() status code: {response.status_code}")
            response.raise_for_status()
            logger.debug(f"Direct requests.get() text snippet: {response.text[:200]}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Direct requests.get() failed: {e}")
        except Exception as e:
            logger.error(f"An unexpected error occurred during direct requests.get(): {e}")

        # スクレイパーが空を返しても、とりあえずダミーを返す
        return [
            Article(
                title="DEBUG: Direct Requests Test Article",
                url="https://debug.example.com/direct-requests",
                summary="This article is returned from a direct requests.get() call in main.py.",
                sentiment="neutral"
            )
        ]
    
    # 他のかてごりは、引き続きダミーデータを返す
    await asyncio.sleep(0.5)  # 非同期処理のシミュレーション

    gamba_article = Article(
        title="ガンバ大阪、週末の試合で劇的勝利！",
        url="https://example.com/gamba-win",
        published_date="2025-09-06",
        summary="宇佐美選手の決勝ゴールで、ガンバ大阪が勝利を収めました。",
        thumbnail_url="https://example.com/images/gamba.jpg",
        sentiment="positive"
    )

    soccer_article = Article(
        title="海外サッカー、日本人選手の活躍まとめ",
        url="https://example.com/soccer-japan",
        published_date="2025-09-06",
        summary="今週の海外リーグで活躍した日本人選手のゴールやアシストを振り返ります。",
        thumbnail_url="https://example.com/images/soccer.jpg",
        sentiment="neutral"
    )

    coffee_article = Article(
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

# --- API Endpoints ---
@app.get("/", tags=["General"])
def read_root():
    return {"message": "Welcome to the News Curation API!"}

@app.get("/articles/{category}", response_model=List[Article], tags=["Articles"])
async def get_articles(category: str):
    """
    指定されたカテゴリの記事を取得します。
    
    - **category**: 記事のカテゴリ (`gamba_osaka`, `soccer`, `coffee`, `programming`)
    """
    articles = await get_articles_for_category(category)
    return articles