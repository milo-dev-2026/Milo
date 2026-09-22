import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

# 看看8090 server block在哪个文件里
cmd = "nginx -T 2>&1 | grep -B20 'listen 8090;' | grep '^# configuration file'"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("Config file for 8090:")
print(stdout.read().decode())

# 看看xianleihuhu-sms.conf在哪个行号被加载
cmd = "nginx -T 2>&1 | grep -n 'xianleihuhu-sms.conf'"
stdin, stdout, stderr = ssh.exec_command(cmd)
print("\nxianleihuhu-sms.conf line numbers:")
print(stdout.read().decode())

ssh.close()
