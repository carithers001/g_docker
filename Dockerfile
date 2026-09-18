FROM alpine:latest

# 1. 安装 dropbear、curl、证书
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

# 3. 关键：编译轻量 hook 库，绕过 Rootless 沙箱对 setgroups/initgroups 的系统调用拦截
RUN apk add --no-cache gcc musl-dev && \
    printf '#include <sys/types.h>\n#include <unistd.h>\n#include <grp.h>\nint setgroups(size_t s, const gid_t *l){return 0;}\nint initgroups(const char *u, gid_t g){return 0;}\nint setgid(gid_t g){return 0;}\nint setuid(uid_t u){return 0;}\n' > /tmp/fix.c && \
    gcc -shared -fPIC -o /lib/libfix.so /tmp/fix.c && \
    rm -f /tmp/fix.c && \
    apk del gcc musl-dev

# 4. 生成主机密钥，并将 root 用户主目录指到可写的 /tmp
RUN sed -i 's|/root:/bin/ash|/tmp:/bin/sh|' /etc/passwd && \
    mkdir -p /etc/dropbear && \
    dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key && \
    echo "root:alpine123" | chpasswd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22222
ENTRYPOINT ["/entrypoint.sh"]
