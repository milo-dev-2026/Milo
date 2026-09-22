import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 找出所有listen 8090的server，以及register location属于哪个server
cmd = "nginx -T 2>&1 | grep -n 'listen 8090\\|/v1/user/register' | head -20"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("Nginx config matches:")
print(stdout.read().decode())

# 看看8090 server block里的第一个location是什么
cmd = "nginx -T 2>&1 | awk '/listen 8090/,/^}/' | head -60"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nFirst 8090 server block:")
print(stdout.read().decode())

ssh.close()
