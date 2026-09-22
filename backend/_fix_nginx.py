import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 读取当前配置
cmd = "cat /etc/nginx/conf.d/xianleihuhu-sms.conf"
stdin, stdout, stderr = ssh.exec_command(cmd)
config = stdout.read().decode()

# 在 /v1/user/login 配置前面加上 /v1/user/register 的配置
new_block = """    # 用户注册
    location /v1/user/register {
        proxy_pass http://sms_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # 用户登录"""

config = config.replace("    # 用户登录", new_block)

# 同时加上邮箱注册和重置密码的路径
email_register_block = """    # 邮箱注册
    location /v1/user/email/register {
        proxy_pass http://sms_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # 重置密码（手机）
    location /v1/user/resetpwd {
        proxy_pass http://sms_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # 重置密码（邮箱）
    location /v1/user/email/resetpwd {
        proxy_pass http://sms_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # 验证码校验接口
    location /v1/user/sms/verifycode {
        proxy_pass http://sms_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # 邮箱验证码校验
    location /v1/user/email/verifycode {
        proxy_pass http://sms_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 10s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # 用户头像上传"""

config = config.replace("    # 用户头像上传", email_register_block)

# 写入新配置
cmd = "cat > /etc/nginx/conf.d/xianleihuhu-sms.conf << 'NGINXEOF'\n" + config + "\nNGINXEOF"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("Write result:", stdout.read().decode(), stderr.read().decode()[:200])

# 测试配置并重载
cmd = "nginx -t && nginx -s reload"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("nginx -t:", stdout.read().decode())
print("nginx reload err:", stderr.read().decode()[:300])

ssh.close()
print("Done!")
