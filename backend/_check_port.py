import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 检查8090端口是什么进程
cmd = "netstat -tlnp | grep 8090"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("8090 port:")
print(stdout.read().decode())

# 检查systemd服务
cmd = "systemctl status xianleihuhu-sms.service | head -20"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nService status:")
print(stdout.read().decode())

# 看看有没有nginx在8090前面
cmd = "nginx -t 2>&1; cat /etc/nginx/conf.d/*.conf 2>/dev/null | grep -A5 8090 | head -30"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nNginx config for 8090:")
print(stdout.read().decode())

ssh.close()
