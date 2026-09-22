import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 读取实际生效的配置
cmd = "cat /www/server/panel/vhost/nginx/xianleihuhu-sms.conf"
stdin, stdout, stderr = ssh.exec_command(cmd)
config = stdout.read().decode()

print("Current config length:", len(config))

# 在"# 用户登录"前面加上 register 的 location
register_block = """    # 用户注册
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

    # 邮箱注册
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

    # 用户登录"""

config = config.replace("    # 用户登录", register_block)

# 写入新配置
sftp = ssh.open_sftp()
with sftp.file('/www/server/panel/vhost/nginx/xianleihuhu-sms.conf', 'w') as f:
    f.write(config)
sftp.close()

print("Config written.")

# 测试并重载
cmd = "nginx -t && nginx -s reload && echo 'RELOAD OK'"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("Result:", stdout.read().decode())
print("Err:", stderr.read().decode()[:300])

# 验证
import time
time.sleep(1)
cmd = "curl -s -X POST http://127.0.0.1:8090/v1/user/register -H 'Content-Type: application/json' -d '{\"zone\":\"0086\",\"phone\":\"13100002222\",\"code\":\"123456\",\"password\":\"test123456\"}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nTest register after fix:")
print(stdout.read().decode()[:200])

ssh.close()
