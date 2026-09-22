import paramiko
import requests
import time

# 发送注册请求
phone = "13400005555"
print(f"Testing register with phone={phone}...")
resp = requests.post(
    "http://43.133.39.170:8090/v1/user/register",
    json={"zone": "0086", "phone": phone, "code": "123456", "password": "test123456"},
    timeout=10
)
print(f"Status: {resp.status_code}")
print(f"Response: {resp.text[:100]}")
print(f"Headers: {dict(resp.headers)}")

time.sleep(2)

# 检查 access.log
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

cmd = "grep " + phone + " /opt/xianleihuhu-sms/access.log"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nAccess log entries for this phone:")
print(stdout.read().decode() or "(none)")

# 检查 WuKongIM 的日志
cmd = "find /opt -name '*.log' -path '*wukong*' 2>/dev/null | head -5; find /opt -name '*.log' -path '*tsdd*' 2>/dev/null | head -5"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nWuKongIM/TSDD log files:")
print(stdout.read().decode())

ssh.close()
