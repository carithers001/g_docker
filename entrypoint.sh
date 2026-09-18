#!/bin/sh
set -e

echo ">> 启动 OpenSSH 服务 (监听 22222)..."
# -D 阻止后台脱离，-e 将错误直接打印到控制台，& 挂入后台
/usr/sbin/sshd -D -e &

# 等待 1 秒检查进程是否存活
sleep 1
if ! pgrep sshd > /dev/null; then
    echo ">> [FATAL] sshd 启动失败！请检查上方报错。"
    exit 1
fi
echo ">> sshd 已成功运行并监听 22222 端口！"

CCC_TOKEN="${ENV_TOKEN:-$TUNNEL_TOKEN}"
if [ -z "$CCC_TOKEN" ]; then
    echo ">> [ERROR] 未检测到 ENV_TONE！"
    exec tail -f /dev/null
fi

echo ">> 启动 Cloudflare Tunnel..."
exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$CCC_TOKEN"
