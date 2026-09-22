import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)
cmd = "tail -20 /opt/xianleihuhu-sms/access.log | grep register"
stdin, stdout, stderr = ssh.exec_command(cmd)
print(stdout.read().decode())
ssh.close()
