FROM alpine:latest

RUN apk add --no-cache openssh-server curl ca-certificates && \
    rm -rf /var/cache/apk/*

RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  CF_ARCH="amd64" ;; \
        aarch64) CF_ARCH="arm64" ;; \
        *) exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 构建期生成 Host Key、建立特权隔离目录、预设密码
RUN ssh-keygen -A && \
    mkdir -p /var/empty && chmod 0755 /var/empty && \
    echo "root:alpine123" | chpasswd

# 关键：端口改为 2222（绕过特权端口限制），PidFile 写入 /tmp
RUN sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PidFile /tmp/sshd.pid" >> /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22222
ENTRYPOINT ["/entrypoint.sh"]
