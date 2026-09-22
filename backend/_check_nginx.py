import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

cmd = "cat /www/server/panel/vhost/nginx/*.conf 2>/dev/null; echo '---'; ls /www/server/panel/vhost/nginx/ 2>/dev/null"
stdin, stdout, stderr = ssh.exec_command(cmd)
print(stdout.read().decode())
print("ERR:", stderr.read().decode()[:200])

ssh.close()
