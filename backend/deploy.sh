#!/bin/bash
# ============================================================
# 雷虎虎验证码服务 - 一键部署脚本
# 支持: CentOS 7+/Ubuntu 18.04+/Debian 10+
# 用法: bash deploy.sh
# ============================================================

set -e

# ==================== 配置项 ====================
APP_NAME="xianleihuhu-sms"
APP_DIR="/opt/${APP_NAME}"
SERVICE_PORT=5001
VENV_DIR="${APP_DIR}/venv"
PYTHON_BIN="python3"
PIP_BIN="pip3"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ==================== 检查 root ====================
if [ "$EUID" -ne 0 ]; then
    log_warn "建议使用 root 用户执行，否则部分安装命令可能需要 sudo"
    SUDO="sudo"
else
    SUDO=""
fi

# ==================== 检测系统 ====================
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        OS_VER=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release) | cut -d. -f1)
    else
        OS="unknown"
        OS_VER="unknown"
    fi
    log_info "检测到系统: $OS $OS_VER"
}

# ==================== 安装依赖 ====================
install_deps() {
    log_info "安装系统依赖..."

    case "$OS" in
        centos|rhel|rocky|almalinux)
            $SUDO yum install -y epel-release 2>/dev/null || true
            $SUDO yum install -y python3 python3-pip python3-devel redis gcc
            # 启动 Redis
            $SUDO systemctl enable redis 2>/dev/null || true
            $SUDO systemctl start redis 2>/dev/null || log_warn "Redis 启动失败，请手动检查"
            ;;
        ubuntu|debian)
            $SUDO apt-get update -y
            $SUDO apt-get install -y python3 python3-pip python3-venv python3-dev redis-server gcc
            # 启动 Redis
            $SUDO systemctl enable redis-server 2>/dev/null || true
            $SUDO systemctl start redis-server 2>/dev/null || log_warn "Redis 启动失败，请手动检查"
            ;;
        *)
            log_error "不支持的系统: $OS，请手动安装 Python3、pip3、redis"
            exit 1
            ;;
    esac

    # 检查 Python 版本
    PYTHON_VER=$($PYTHON_BIN -c 'import sys; print(".".join(map(str, sys.version_info[:2])))' 2>/dev/null || echo "0.0")
    log_info "Python 版本: $PYTHON_VER"
}

# ==================== 创建应用目录 ====================
setup_app_dir() {
    log_info "创建应用目录: $APP_DIR"
    $SUDO mkdir -p "$APP_DIR"

    # 复制当前目录下的应用文件
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    log_info "从 $SCRIPT_DIR 复制应用文件..."

    for f in app.py config.py requirements.txt; do
        if [ -f "$SCRIPT_DIR/$f" ]; then
            $SUDO cp "$SCRIPT_DIR/$f" "$APP_DIR/"
            log_info "  已复制 $f"
        else
            log_warn "  未找到 $f，跳过"
        fi
    done

    # 部署 Nginx 配置
    if [ -f "$SCRIPT_DIR/xianleihuhu-sms.nginx.conf" ]; then
        $SUDO cp "$SCRIPT_DIR/xianleihuhu-sms.nginx.conf" /etc/nginx/conf.d/
        log_info "  已复制 nginx 配置"
        # 重载 nginx
        $SUDO nginx -t 2>/dev/null && $SUDO systemctl reload nginx 2>/dev/null || log_warn "nginx 重载失败，请手动检查"
    fi
}

# ==================== 创建虚拟环境 ====================
create_venv() {
    log_info "创建 Python 虚拟环境..."

    if [ -d "$VENV_DIR" ]; then
        log_warn "虚拟环境已存在，跳过创建"
    else
        $SUDO $PYTHON_BIN -m venv "$VENV_DIR"
    fi

    # 激活虚拟环境并安装依赖
    log_info "安装 Python 依赖..."
    $SUDO "$VENV_DIR/bin/pip" install --upgrade pip
    $SUDO "$VENV_DIR/bin/pip" install -r "$APP_DIR/requirements.txt"
}

# ==================== 配置环境变量 ====================
setup_env() {
    ENV_FILE="${APP_DIR}/.env"

    if [ -f "$ENV_FILE" ]; then
        log_warn ".env 文件已存在，跳过配置"
        return
    fi

    log_info "创建环境变量配置文件..."

    # 交互式输入配置
    read -p "请输入阿里云 AccessKey ID: " ALIYUN_AK
    read -p "请输入阿里云 AccessKey Secret: " ALIYUN_SK
    read -p "请输入短信签名名称 (默认: 恒创联众): " SMS_SIGN
    SMS_SIGN=${SMS_SIGN:-恒创联众}
    read -p "请输入短信模板CODE (默认: 100001): " SMS_TPL
    SMS_TPL=${SMS_TPL:-100001}
    read -p "请输入 Resend API Key: " RESEND_KEY
    read -p "请输入发件人邮箱 (默认: noreply@xn--y71aa709j.cc): " FROM_EMAIL
    FROM_EMAIL=${FROM_EMAIL:-noreply@xn--y71aa709j.cc}
    read -p "请输入发件人名称 (默认: 雷虎虎): " FROM_NAME
    FROM_NAME=${FROM_NAME:-雷虎虎}
    read -p "请输入服务端口 (默认: 5001): " PORT
    PORT=${PORT:-5001}
    read -p "请输入 Redis 密码 (没有则留空): " REDIS_PWD

    $SUDO tee "$ENV_FILE" > /dev/null <<EOF
# 阿里云号码认证服务
ALIYUN_ACCESS_KEY_ID=${ALIYUN_AK}
ALIYUN_ACCESS_KEY_SECRET=${ALIYUN_SK}
ALIYUN_SMS_SIGN_NAME=${SMS_SIGN}
ALIYUN_SMS_TEMPLATE_CODE=${SMS_TPL}

# Resend 邮箱服务
RESEND_API_KEY=${RESEND_KEY}
RESEND_FROM_EMAIL=${FROM_EMAIL}
RESEND_FROM_NAME=${FROM_NAME}

# Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PWD}
REDIS_DB=0

# 服务配置
HOST=0.0.0.0
PORT=${PORT}
DEBUG=false
EOF

    log_info "环境变量配置已保存到 $ENV_FILE"
}

# ==================== 配置 systemd 服务 ====================
setup_systemd() {
    log_info "配置 systemd 服务..."

    SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"

    $SUDO tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Xianleihuhu SMS/Email Verification Service
After=network.target redis.service

[Service]
Type=simple
User=root
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
ExecStart=${VENV_DIR}/bin/gunicorn -w 2 -b 0.0.0.0:${SERVICE_PORT} --timeout 30 --access-logfile ${APP_DIR}/access.log --error-logfile ${APP_DIR}/error.log app:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # 安装 gunicorn
    $SUDO "$VENV_DIR/bin/pip" install gunicorn

    # 重载并启动服务
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable ${APP_NAME}
    $SUDO systemctl restart ${APP_NAME}

    sleep 2

    # 检查服务状态
    if $SUDO systemctl is-active --quiet ${APP_NAME}; then
        log_info "服务启动成功！"
        $SUDO systemctl status ${APP_NAME} --no-pager -l | head -10
    else
        log_error "服务启动失败，查看日志:"
        $SUDO journalctl -u ${APP_NAME} --no-pager -n 20
    fi
}

# ==================== 开放防火墙 ====================
setup_firewall() {
    log_info "配置防火墙开放端口 ${SERVICE_PORT}..."

    case "$OS" in
        centos|rhel|rocky|almalinux)
            if command -v firewall-cmd &>/dev/null; then
                $SUDO firewall-cmd --permanent --add-port=${SERVICE_PORT}/tcp 2>/dev/null || true
                $SUDO firewall-cmd --reload 2>/dev/null || true
            fi
            ;;
        ubuntu|debian)
            if command -v ufw &>/dev/null; then
                $SUDO ufw allow ${SERVICE_PORT}/tcp 2>/dev/null || true
            fi
            ;;
    esac
}

# ==================== 验证部署 ====================
verify_deploy() {
    log_info "验证部署结果..."
    sleep 1

    if command -v curl &>/dev/null; then
        RESP=$(curl -s http://127.0.0.1:${SERVICE_PORT}/health 2>/dev/null || echo "")
        if echo "$RESP" | grep -q '"status":"ok"'; then
            log_info "✅ 部署成功！服务运行正常"
            echo ""
            echo "服务地址: http://0.0.0.0:${SERVICE_PORT}"
            echo "健康检查: curl http://127.0.0.1:${SERVICE_PORT}/health"
            echo "服务管理:"
            echo "  启动: systemctl start ${APP_NAME}"
            echo "  停止: systemctl stop ${APP_NAME}"
            echo "  重启: systemctl restart ${APP_NAME}"
            echo "  状态: systemctl status ${APP_NAME}"
            echo "  日志: journalctl -u ${APP_NAME} -f"
            echo ""
        else
            log_error "❌ 服务健康检查失败: $RESP"
        fi
    else
        log_warn "curl 不可用，请手动访问 http://127.0.0.1:${SERVICE_PORT}/health 验证"
    fi
}

# ==================== 主流程 ====================
main() {
    echo "=========================================="
    echo "  雷虎虎验证码服务 - 一键部署"
    echo "=========================================="
    echo ""

    detect_os
    install_deps
    setup_app_dir
    create_venv
    setup_env
    setup_systemd
    setup_firewall
    verify_deploy

    echo ""
    log_info "部署完成！"
}

main "$@"
