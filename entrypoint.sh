#!/bin/sh
set -e

echo ">> 启动 Dropbear SSH 服务 (加载 LD_PRELOAD 兼容层)..."
# 注入 libfix.so 绕过 setgroups 拦截
LD_PRELOAD=/lib/libfix.so /usr/sbin/dropbear -E -F -p 22222 -P /tmp/dropbear.pid &

sleep 1
if ! pgrep dropbear > /dev/null; then
    echo ">> [FATAL] dropbear 启动失败！"
    exit 1
fi
echo ">> Dropbear SSH 服务已就绪！"

CCC_TOKEN="${ENV_TOKEN:-$TUNNEL_TOKEN}"
if [ -z "$CCC_TOKEN" ]; then
    echo ">> [ERROR] 未检测到 ENV_TONE！"
    exec tail -f /dev/null
fi

echo ">> 启动 Cloudflare Tunnel..."
exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$CCC_TOKEN"
