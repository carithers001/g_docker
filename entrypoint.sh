#!/bin/bash
set -e

# 1. 确保 SSH Host Keys 存在（避免每次构建时硬编码固化密钥）
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo ">> 生成 SSH 主机密钥..."
    ssh-keygen -A
fi

# 2. 设置 root 密码（如平台环境变量传入 SSH_PASSWORD 则使用，否则默认设置一个临时密码）
SSH_PASSWORD=${SSH_PASSWORD:-"linux"}
echo "root:${SSH_PASSWORD}" | chpasswd
echo ">> Root 密码已更新."

# 3. 后台启动 sshd 服务
echo ">> 正在启动 OpenSSH 服务..."
/usr/sbin/sshd

# 4. 启动 cloudflared 穿透
# 优先读取你配置的 ENV_TONE，若不存在则回退至 TUNNEL_TOKEN
TOKEN="${ENV_TONE:-$TUNNEL_TOKEN}"

if [ -z "$TOKEN" ]; then
    echo ">> [ERROR] 未检测到 ENV_TONE 环境变量，cloudflared 无法启动！"
    echo ">> 容器将保持后台挂起以便调试..."
    tail -f /dev/null
else
    echo ">> 检测到 Cloudflare Token，正在启动 Cloudflare Tunnel..."
    # 使用 exec 让 cloudflared 成为 1 号前台守护进程，负责捕获容器信号
    exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TOKEN"
fi
