FROM alpine:latest

# 设置非交互环境变量
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装 OpenSSH、curl、bash、ca-certificates 等基础组件并清理缓存
RUN apk add --no-cache \
        openssh-server \
        openssh-sftp-server \
        curl \
        bash \
        ca-certificates \
    && rm -rf /var/cache/apk/*

# 2. 根据系统架构自动拉取静态编译的官方 cloudflared 二进制文件（体积最小、无需多余动态库依赖）
RUN ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64)  CF_ARCH="amd64" ;; \
        aarch64) CF_ARCH="arm64" ;; \
        armv7l)  CF_ARCH="arm" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 3. 基础 SSHD 配置：允许 root 密码登录并预留运行所需运行时目录
RUN mkdir -p /var/run/sshd /root/.ssh && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 4. 复制启动引导脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露 SSH 端口（内部监听）
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
