FROM alpine:latest

# 1. 安装 OpenSSH、curl、证书
RUN apk add --no-cache openssh-server curl ca-certificates && \
    rm -rf /var/cache/apk/*

# 2. 下载官方静态版 cloudflared
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  CF_ARCH="amd64" ;; \
        aarch64) CF_ARCH="arm64" ;; \
        *) echo "Unsupported arch: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3. 关键：在构建期（可写）生成 Host Key、创建特权隔离目录、预设密码
RUN ssh-keygen -A && \
    mkdir -p /var/empty && chmod 0755 /var/empty && \
    echo "root:alpine123" | chpasswd

# 4. 配置 SSHD：允许 root 密码登录，将 PID 文件重定向到只读环境唯一可写的 /tmp
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PidFile /tmp/sshd.pid" >> /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
