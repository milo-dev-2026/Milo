import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

cmd = "sed -n '236,250p' /etc/nginx/conf.d/xianleihuhu-sms.conf"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("Lines 236-250:")
print(stdout.read().decode())

# 检查 nginx 实际加载的配置
cmd = "nginx -T 2>&1 | grep -A5 '/v1/user/register' | head -20"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nnginx -T register:")
print(stdout.read().decode())

ssh.close()
