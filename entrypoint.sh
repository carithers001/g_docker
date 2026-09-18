#!/bin/sh
set -e

echo ">> 启动 Dropbear SSH 服务 (监听 22222)..."
# -E: 日志直接输出到终端
# -F: 前台模式（通过 & 挂后台守护）
# -p: 指定高位端口 22222
# -P: 指定 PID 文件写入唯一可读写的内存盘 /tmp（防止只读报错）
/usr/sbin/dropbear -E -F -p 22222 -P /tmp/dropbear.pid &

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
