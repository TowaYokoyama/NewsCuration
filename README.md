# News Curation App

自分用のニュース・記事キュレーションアプリです。バックエンドはPython (FastAPI)、フロントエンドはFlutterで構築されています。

## 必要なもの

プロジェクトを実行するには、以下のツールがインストールされている必要があります。

- [Docker](https://www.docker.com/)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

## バックエンドのセットアップ

バックエンドはDockerコンテナ内で実行されます。

1. **Dockerイメージをビルドする:**

   プロジェクトのルートディレクトリで以下のコマンドを実行します。

   ```bash
   docker build -t newscuration-backend -f backend/Dockerfile backend
   ```

2. **Dockerコンテナを実行する:**

   ```bash
   docker run -d -p 8000:8000 newscuration-backend
   ```

3. **確認:**

   APIサーバーが `http://localhost:8000` で起動します。
   APIドキュメントは `http://localhost:8000/docs` で確認できます。

## フロントエンドのセットアップ

フロントエンドはFlutterで構築されています。

1. **フロントエンドのディレクトリに移動する:**

   ```bash
   cd frontend
   ```

2. **依存関係をインストールする:**

   ```bash
   flutter pub get
   ```

3. **アプリケーションを実行する (Web):**

   Chromeでアプリケーションを起動します。

   ```bash
   flutter run -d chrome
   ```

4. **アプリケーションを実行する (モバイル):**

   Androidエミュレータを起動するか、実機を接続してから以下のコマンドを実行します。

   ```bash
   flutter run
   ```
# NewsCuration
