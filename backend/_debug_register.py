import paramiko
import time
import requests

# 发送注册请求
phone = "13600007777"
print(f"Testing register with phone={phone}...")
resp = requests.post(
    "http://43.133.39.170:8090/v1/user/register",
    json={"zone": "0086", "phone": phone, "code": "123456", "password": "test123456"},
    timeout=10
)
print(f"Status: {resp.status_code}")
print(f"Response: {resp.text[:200]}")

time.sleep(2)

# 检查日志
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

cmd = "tail -5 /opt/xianleihuhu-sms/access.log"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nAccess log tail:")
print(stdout.read().decode())

cmd = "grep " + phone + " /opt/xianleihuhu-sms/error.log | tail -5"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nError log for phone:")
print(stdout.read().decode())

ssh.close()
