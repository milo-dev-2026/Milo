import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 在服务器上直接测试8090
cmd = "curl -v -s -X POST http://127.0.0.1:8090/v1/user/register -H 'Content-Type: application/json' -d '{\"zone\":\"0086\",\"phone\":\"13200003333\",\"code\":\"123456\",\"password\":\"test123456\"}' 2>&1 | head -40"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("8090 test:")
print(stdout.read().decode())

ssh.close()
