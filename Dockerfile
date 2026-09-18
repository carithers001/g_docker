FROM alpine:latest

# 1. 安装 dropbear、curl 和证书
RUN apk add --no-cache dropbear curl ca-certificates && \
    rm -rf /var/cache/apk/*

# 2. 下载官方静态编译版 cloudflared
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  CF_ARCH="amd64" ;; \
        aarch64) CF_ARCH="arm64" ;; \
        *) exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3. 关键修复：
# - 剥离 /etc/group 中所有组的附加成员，防止 initgroups() 尝试绑定未映射 GID
# - 将 root 的 home 目录切到 /tmp，避免只读文件系统下缺少可写目录
# - 补齐 dropbear 常见主机密钥（ed25519, rsa, ecdsa）
RUN cut -d: -f1-3 /etc/group | sed 's/$/:/' > /etc/group.clean && \
    mv /etc/group.clean /etc/group && \
    sed -i 's|/root:/bin/ash|/tmp:/bin/sh|' /etc/passwd && \
    mkdir -p /etc/dropbear && \
    dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key && \
    dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key && \
    echo "root:alpine123" | chpasswd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22222
ENTRYPOINT ["/entrypoint.sh"]
