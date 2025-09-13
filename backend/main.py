# -*- coding: utf-8 -*-
import logging

from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from typing import List
import asyncio
import requests

# scraper.pyから実際のスクレイピング関数をインポート (一時的にコメントアウト)
# from scraper import scrape_programming_news
# models.pyから共有データモデルをインポート
import schemas
from core.security import get_current_user

# Import the new auth router
from api import auth, articles

# ロギング設定
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# --- FastAPI Application ---
app = FastAPI(
    title="News Curation API",
    description="指定されたサイトから記事を収集し、感情分析（またはキーワード抽出）を行うAPIです。",
    version="0.1.0",
)

# --- CORS Middleware (FastAPIの標準ミドルウェアを使用) ---
origins = ["*"] # 開発中は全て許可

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- API Routers ---
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(articles.router, prefix="/api/articles", tags=["Articles"])

# --- API Endpoints ---
@app.get("/", tags=["General"])
def read_root():
    return {"message": "Welcome to the News Curation API!"}
