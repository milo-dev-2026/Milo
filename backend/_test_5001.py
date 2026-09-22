import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 直接请求5001端口测试验证码校验
cmd = "curl -s -X POST http://127.0.0.1:5001/v1/user/register -H 'Content-Type: application/json' -d '{\"zone\":\"0086\",\"phone\":\"13300004444\",\"code\":\"123456\",\"password\":\"test123456\"}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("Direct 5001 response:")
print(stdout.read().decode()[:300])
print("ERR:", stderr.read().decode()[:200])

# 检查 access.log
cmd = "grep 13300004444 /opt/xianleihuhu-sms/access.log"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nAccess log:")
print(stdout.read().decode() or "(none)")

# 检查 error.log
cmd = "grep 13300004444 /opt/xianleihuhu-sms/error.log | tail -5"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nError log:")
print(stdout.read().decode() or "(none)")

ssh.close()
