# backend/api/categories.py
from fastapi import APIRouter, Depends
from typing import List
import logging

from scraper import get_rakuten_categories
from models import RecipeCategory

router = APIRouter()
logger = logging.getLogger(__name__)

# Map frontend category names to Rakuten Recipe Parent Category IDs
RAKUTEN_PARENT_CATEGORY_MAP = {
    "cooking": "38", # 今日の献立 (Today's Menu)
    "coffee": "27",  # 飲みもの (Drinks)
}

@router.get("/{parent_category_name}", response_model=List[RecipeCategory])
async def get_recipe_subcategories(parent_category_name: str):
    """
    指定された親カテゴリ名に基づいて、楽天レシピのサブカテゴリリストを取得します。
    """
    parent_id = RAKUTEN_PARENT_CATEGORY_MAP.get(parent_category_name)
    if not parent_id:
        return []
    
    return await get_rakuten_categories(parent_id)
