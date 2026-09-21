# 雷虎虎验证码服务 - 部署说明

## 文件清单

| 文件 | 说明 |
|------|------|
| `app.py` | 主应用程序（Flask） |
| `config.py` | 配置文件（优先从 .env 读取） |
| `requirements.txt` | Python 依赖列表 |
| `deploy.sh` | 一键部署脚本（推荐） |
| `xianleihuhu-sms.nginx.conf` | Nginx 反向代理配置（可选） |

---

## 方式一：一键部署（推荐）

### 步骤

1. **上传文件到服务器**

   将整个 `backend` 目录上传到服务器，比如 `/root/backend/`

   ```bash
   # 本地执行（Windows 用 scp 或其他工具）
   scp -r backend/* root@43.133.39.170:/root/backend/
   ```

2. **执行部署脚本**

   ```bash
   cd /root/backend
   chmod +x deploy.sh
   bash deploy.sh
   ```

   脚本会自动完成：
   - 安装 Python3、pip、Redis
   - 创建虚拟环境并安装依赖
   - 交互式配置密钥（阿里云、Resend）
   - 配置 systemd 服务并启动
   - 开放防火墙端口

3. **验证**

   ```bash
   curl http://127.0.0.1:5001/health
   ```

   返回 `{"status":"ok",...}` 即为成功。

---

## 方式二：手动部署

### 1. 安装系统依赖

**CentOS/RHEL:**
```bash
yum install -y epel-release
yum install -y python3 python3-pip python3-devel redis gcc
systemctl enable redis && systemctl start redis
```

**Ubuntu/Debian:**
```bash
apt-get update
apt-get install -y python3 python3-pip python3-venv python3-dev redis-server gcc
systemctl enable redis-server && systemctl start redis-server
```

### 2. 创建应用目录

```bash
mkdir -p /opt/xianleihuhu-sms
cd /opt/xianleihuhu-sms
# 上传 app.py, config.py, requirements.txt 到这里
```

### 3. 创建虚拟环境

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. 配置环境变量

```bash
cat > .env << 'EOF'
# 阿里云号码认证服务
ALIYUN_ACCESS_KEY_ID=你的AccessKeyID
ALIYUN_ACCESS_KEY_SECRET=你的AccessKeySecret
ALIYUN_SMS_SIGN_NAME=恒创联众
ALIYUN_SMS_TEMPLATE_CODE=100001

# Resend 邮箱服务
RESEND_API_KEY=你的ResendKey
RESEND_FROM_EMAIL=noreply@xn--y71aa709j.cc
RESEND_FROM_NAME=雷虎虎

# Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# 服务配置
HOST=0.0.0.0
PORT=5001
DEBUG=false
EOF
```

### 5. 配置 systemd 服务

```bash
cat > /etc/systemd/system/xianleihuhu-sms.service << 'EOF'
[Unit]
Description=Xianleihuhu SMS/Email Verification Service
After=network.target redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/xianleihuhu-sms
EnvironmentFile=/opt/xianleihuhu-sms/.env
ExecStart=/opt/xianleihuhu-sms/venv/bin/gunicorn -w 2 -b 0.0.0.0:5001 --timeout 30 --access-logfile /opt/xianleihuhu-sms/access.log --error-logfile /opt/xianleihuhu-sms/error.log app:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xianleihuhu-sms
systemctl start xianleihuhu-sms
```

### 6. 验证

```bash
curl http://127.0.0.1:5001/health
systemctl status xianleihuhu-sms
```

---

## Nginx 反向代理（可选）

如果要和现有服务共用 8090 端口，使用 `xianleihuhu-sms.nginx.conf`：

```bash
cp xianleihuhu-sms.nginx.conf /etc/nginx/conf.d/
nginx -t
systemctl reload nginx
```

代理后访问路径：
- `http://服务器IP:8090/v1/user/sms/registercode`
- `http://服务器IP:8090/v1/user/email/registercode`

---

## 常用运维命令

```bash
# 查看服务状态
systemctl status xianleihuhu-sms

# 重启服务
systemctl restart xianleihuhu-sms

# 查看实时日志
journalctl -u xianleihuhu-sms -f

# 查看最近 50 行日志
journalctl -u xianleihuhu-sms -n 50 --no-pager

# 修改配置后
vim /opt/xianleihuhu-sms/.env
systemctl restart xianleihuhu-sms
```

---

## API 接口列表

### 健康检查
```
GET /health
```

### 短信验证码
```
POST /v1/user/sms/registercode   发送注册验证码
POST /v1/user/sms/verifycode     校验验证码
POST /v1/user/sms/register       手机号注册
POST /v1/user/sms/forgetpwd      发送忘记密码验证码
POST /v1/user/sms/pwdforget      手机号重置密码
```

### 邮箱验证码
```
POST /v1/user/email/registercode  发送注册验证码
POST /v1/user/email/verifycode    校验验证码
POST /v1/user/email/register      邮箱注册
POST /v1/user/email/forgetpwd     发送忘记密码验证码
POST /v1/user/email/pwdforget     邮箱重置密码
```

### 账号检查
```
POST /v1/user/isregister  检查账号是否已注册
```

---

## 安全说明

1. **密钥安全**：`.env` 文件权限设为 600，仅 root 可读
   ```bash
   chmod 600 /opt/xianleihuhu-sms/.env
   ```

2. **Redis 密码**：生产环境建议给 Redis 设置密码

3. **防火墙**：如不使用 Nginx 代理，建议只开放必要端口

4. **HTTPS**：生产环境建议配置 HTTPS（通过 Nginx 加证书）
