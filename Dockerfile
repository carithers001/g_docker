FROM alpine:latest

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装 OpenSSH、curl、ca-certificates
RUN apk add --no-cache \
        openssh-server \
        openssh-sftp-server \
        curl \
        ca-certificates \
    && rm -rf /var/cache/apk/*

# 2. 下载并安装 cloudflared
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  CF_ARCH="amd64" ;; \
        aarch64) CF_ARCH="arm64" ;; \
        armv7l)  CF_ARCH="arm" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3. 关键：在构建阶段生成 Host Keys 并设置 Root 密码（构建期允许写入）
RUN ssh-keygen -A && \
    echo "root:alpine123" | chpasswd

# 4. 配置 SSH 服务：允许 Root 登录，同时将 PID 文件和运行时目录重定向到 /tmp
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PidFile /tmp/sshd.pid" >> /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
