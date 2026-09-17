FROM python:3.13-slim

WORKDIR /app

# 1. 核心环境变量
# - PYTHONUNBUFFERED=1 / -u: 强制无缓冲实时打印日志，防止日志憋在内存里不显示
# - PATH & PYTHONPATH: 提前把 /tmp 注入搜索路径，确保动态生成的脚本和包能被识别
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/tmp:/tmp/bin:/app:${PATH}" \
    PYTHONPATH="/tmp:/app"

# 2. 安装系统基础运行依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 3. 安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. 复制代码到镜像静态目录 /app
COPY . /app

# 5. 方案B核心启动指令：
# ① 打印调试锚点，确认每一步执行状态
# ② 将 /app 完整拷贝到平台开放写权限的 /tmp 目录
# ③ 为 /tmp 赋予可执行权限
# ④ 切换工作目录到 /tmp
# ⑤ 使用 exec 替换 shell 进程为 Python 进程（保证信号响应与容器 PID 存活）
CMD ["sh", "-c", "echo '==> [1/3] 正在同步代码到可写目录 /tmp ...' && cp -r /app/. /tmp/ && chmod -R 755 /tmp && cd /tmp && echo '==> [2/3] 当前路径已切为可写区: '$(pwd) && echo '==> [3/3] 启动主程序 main.py ...' && exec python -u main.py"]
