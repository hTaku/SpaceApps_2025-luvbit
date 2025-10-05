FROM python:3.11-slim

WORKDIR /app/app

# Pythonパッケージをインストール
COPY ./backend/requirements.txt /app/

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# 環境変数の設定
ENV PYTHONPATH=/app
ENV PORT=8000

# ポートの公開
EXPOSE 8000

# アプリケーションの起動
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]