import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

cmd = "grep -n 'register\\|resetpwd\\|verifycode' /etc/nginx/conf.d/xianleihuhu-sms.conf"
stdin, stdout, stderr = ssh.exec_command(cmd)
print(stdout.read().decode())

ssh.close()
