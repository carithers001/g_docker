#!/bin/sh
set -e

echo ">> 启动 OpenSSH 服务..."
# -e 强制将 sshd 的错误输出重定向到控制台，不再静默沉没
/usr/sbin/sshd -e

CCC_TOKEN="${ENV_TOKEN:-$TUNNEL_TOKEN}"
if [ -z "$CCC_TOKEN" ]; then
    echo ">> [ERROR] 未检测到 ENV_TONE！"
    exec tail -f /dev/null
fi

echo ">> 启动 Cloudflare Tunnel..."
exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$CCC_TOKEN"
