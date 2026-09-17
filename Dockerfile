FROM python:3.13-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/tmp:/tmp/bin:/app:${PATH}" \
    PYTHONPATH="/tmp:/app"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# 纯粹的拷贝、切换目录并启动，不执行任何多余的 chmod
CMD ["sh", "-c", "cp -r /app/. /tmp/ && cd /tmp && exec python -u main.py"]
