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
COPY . /code

# 关键：把 /app 建立为指向 /tmp 的软链接
# 这样代码访问 /app/xxx 时，实际写入的是可写的 /tmp/xxx
RUN ln -s /tmp /app

# 启动时：把 /code 下的代码同步进 /tmp，然后进入 /tmp 启动
CMD ["sh", "-c", "cp -r /code/. /tmp/ && cd /tmp && exec python -u main.py"]
