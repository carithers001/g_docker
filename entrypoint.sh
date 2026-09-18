#!/bin/sh
set -e

echo ">> 正在初始化运行时可写目录..."
# 确保 SSHD 运行时所依赖的空目录在 /tmp 中准备就绪
mkdir -p /tmp/run/sshd /tmp/empty
chmod 0755 /tmp/run/sshd

# 启动 OpenSSH 服务（指定参数避免依赖 /var/run/sshd）
echo ">> 正在启动 OpenSSH 服务..."
/usr/sbin/sshd -o "PidFile=/tmp/sshd.pid"

# 读取 Cloudflare Token 并运行
CCC_TOKEN="${ENV_TOKEN:-$TUNNEL_TOKEN}"

if [ -z "$CCC_TOKEN" ]; then
    echo ">> [ERROR] 未检测到 ENV_TONE 环境变量，cloudflared 无法启动！"
    exec tail -f /dev/null
else
    echo ">> 启动 Cloudflare Tunnel..."
    exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$CCC_TOKEN"
fi
