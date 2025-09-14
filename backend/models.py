# -*- coding: utf-8 -*-
# models.py

from pydantic import BaseModel
from typing import Optional

# アプリケーション全体で共有されるデータモデルを定義します。
class Article(BaseModel):
    """
    単一の記事を表すPydanticデータモデル。
    このモデルを別のファイルに分離することで、循環インポートを回避します。
    """
    title: str
    url: str
    published_date: Optional[str] = None
    summary: Optional[str] = None
    thumbnail_url: Optional[str] = None
    sentiment: Optional[str] = "neutral"

class RecipeCategory(BaseModel):
    """
    楽天レシピのカテゴリを表すモデル。
    """
    categoryId: str
    categoryName: str
