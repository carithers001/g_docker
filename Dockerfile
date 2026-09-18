FROM alpine:latest

# 1. 安装 dropbear (极简嵌入式 SSH，无沙箱冲突)、curl 和证书
RUN apk add --no-cache dropbear curl ca-certificates && \
    rm -rf /var/cache/apk/*

# 2. 下载官方静态版 cloudflared
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  CF_ARCH="amd64" ;; \
        aarch64) CF_ARCH="arm64" ;; \
        *) exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3. 构建期生成 Dropbear 密钥并配置 root 密码
RUN mkdir -p /etc/dropbear && \
    dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key && \
    echo "root:alpine123" | chpasswd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22222
ENTRYPOINT ["/entrypoint.sh"]
