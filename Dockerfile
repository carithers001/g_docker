# 1. 基础镜像：Python 3.13 精简版 (Debian-based)
FROM python:3.13-slim

# 2. 设置环境变量：禁用字节码写入并强制实时输出标准输出/错误流
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 3. 设置容器内工作目录
WORKDIR /app

# 4. 优化缓存层：先复制依赖清单并安装
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. 复制代码到工作目录
COPY . .

# 6. 运行入口
CMD ["python", "main.py"]
