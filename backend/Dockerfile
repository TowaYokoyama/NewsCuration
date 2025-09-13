# ベースとなるDockerイメージを指定します。
# Python 3.11の軽量版(slim)を使用することで、イメージサイズを小さく抑えます。
FROM python:3.11-slim

# コンテナ内での作業ディレクトリを設定します。
# これ以降のコマンドは、この`/app`ディレクトリ内で実行されます。
WORKDIR /app

# curlとgnupgをインストールしてネットワークデバッグを可能にする
RUN apt-get update && apt-get install -y curl gnupg && rm -rf /var/lib/apt/lists/*

# まず、ライブラリの依存関係を定義したrequirements.txtファイルをコンテナにコピーします。
# このように、ソースコード全体をコピーする前にライブラリをインストールすることで、
# ソースコードの変更時にDockerのレイヤーキャッシュが効き、ビルド時間を短縮できます。
COPY requirements.txt .

# requirements.txtに記載されたライブラリをpipでインストールします。
# --no-cache-dir オプションは、キャッシュを保存しないことでイメージサイズを削減します。
RUN pip install --no-cache-dir -r requirements.txt

# プロジェクトの全てのファイルとディレクトリを、コンテナの作業ディレクトリ(/app)にコピーします。
COPY . .

# コンテナが起動したときに実行されるコマンドを指定します。
# uvicornサーバーを起動し、FastAPIアプリケーション(main.pyの中のapp)を実行します。
# --host 0.0.0.0 を指定することで、コンテナの外部からアクセスできるようになります。
# --port 8001 で、8001番ポートでリクエストを待ち受けます。
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]