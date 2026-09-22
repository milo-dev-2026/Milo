import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)
cmd = "redis-cli get 'sms:register:phone:13700008888'"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("stored_code:", repr(stdout.read().decode().strip()))
print("ERR:", stderr.read().decode())
ssh.close()
