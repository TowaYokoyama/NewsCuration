# backend/core/recommender.py
from sklearn.feature_extraction.text import TfidfVectorizer #"textをTF=IDベクトルに変えるためのライブラリ"
from sklearn.metrics.pairwise import cosine_similarity #コサイン類似度を計算する関数
from janome.tokenizer import Tokenizer #日本語の形態素解析ライブらり
from sqlalchemy.orm import Session #Db接続を持つsession 
import numpy as np #numpy

import crud #自作のモジュール　dbのcrudまとめ
import db_models as models #自作のdbモデル定義

# Janome tokenizerの初期化
t = Tokenizer()

def tokenize(text: str) -> list[str]:
    """日本語のテキストを単語（名詞、動詞、形容詞の原型）に分割する"""
    return [token.base_form for token in t.tokenize(text) 
            if token.part_of_speech.split(',')[0] in ['名詞', '動詞', '形容詞']]

def generate_recommendations(db: Session, user: models.User, top_n=10) -> list[models.Article]:
    """ユーザーのお気に入りに基づいて記事を推薦する"""
    favorite_articles = crud.get_favorite_articles(db, user=user)
    all_articles = crud.get_all_articles(db)

    if not favorite_articles or not all_articles:
        return []

    # ユーザーがお気に入りにした記事のIDセット
    favorite_ids = {article.id for article in favorite_articles}

    # 推薦候補の記事（お気に入り以外）
    candidate_articles = [article for article in all_articles if article.id not in favorite_ids]
    if not candidate_articles:
        return []

    # コーパス（記事のテキスト集）を作成
    # 候補記事 + お気に入り記事 の順
    corpus = [(a.title or '') + ' ' + (a.summary or '') for a in candidate_articles + favorite_articles]
    
    # TF-IDFベクトル化
    vectorizer = TfidfVectorizer(tokenizer=tokenize)
    tfidf_matrix = vectorizer.fit_transform(corpus)

    # お気に入り記事のベクトルを平均してユーザープロファイルを作成
    num_candidates = len(candidate_articles)
    favorite_vectors = tfidf_matrix[num_candidates:]
    user_profile = np.mean(favorite_vectors, axis=0)
    user_profile = np.asarray(user_profile) # Convert from np.matrix to np.ndarray

    # 候補記事のベクトル
    candidate_vectors = tfidf_matrix[:num_candidates]

    # コサイン類似度を計算
    similarities = cosine_similarity(user_profile, candidate_vectors)

    # 類似度が高い順にソートし、インデックスを取得
    sorted_indices = np.argsort(similarities[0])[::-1]

    # 上位N件の記事を返す
    recommended_articles = [candidate_articles[i] for i in sorted_indices[:top_n]]

    return recommended_articles
