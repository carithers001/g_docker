FROM python:3.13-slim

WORKDIR /app

# 1. 配置核心环境变量
# - PATH: 将 /app 及子脚本目录加入系统命令路径，可直接当作命令执行
# - PYTHONPATH: 确保任意子目录下的 Python 脚本互相 import 时不会报 ModuleNotFoundError
ENV PATH="/app:/app/bin:${PATH}" \
    PYTHONPATH="/app" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# 2. 安装系统基础库（如果部分程序需要网络工具、编译依赖或 bash）
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 3. 安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. 拷贝完整项目代码
COPY . /app

# 5. 赋予 /app 下所有脚本和可执行文件执行权限 (+x)
RUN chmod -R +x /app

# 6. 默认入口（在启动容器时可随时覆盖）
CMD ["python", "main.py"]
