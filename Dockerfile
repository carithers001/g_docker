FROM python:3.13-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 把代码存放在一个静态备用目录 /code
WORKDIR /code
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app

# 启动时：把 /code 下的代码同步进 /tmp，然后进入 /tmp 启动
CMD ["python", "main.py"]
