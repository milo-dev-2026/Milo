import paramiko
import json
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.133.39.170', username='root', password='Lixin123', timeout=15)

phone = "13000001111"

# 1. 发送验证码
cmd = f"curl -s -X POST http://127.0.0.1:8090/v1/user/sms/registercode -H 'Content-Type: application/json' -d '{{\"phone\":\"{phone}\"}}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
send_result = stdout.read().decode()
print("Send code:", send_result)

# 2. 从Redis获取验证码
cmd = f"redis-cli get 'sms:register:phone:{phone}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
real_code = stdout.read().decode().strip()
print(f"Real code from Redis: '{real_code}'")

# 3. 用正确的验证码注册
cmd = f"curl -s -X POST http://127.0.0.1:8090/v1/user/register -H 'Content-Type: application/json' -d '{{\"zone\":\"0086\",\"phone\":\"{phone}\",\"code\":\"{real_code}\",\"password\":\"test123456\"}}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
reg_result = stdout.read().decode()
print("\nRegister with correct code:")
data = json.loads(reg_result)
if "uid" in data:
    print(f"  SUCCESS! uid={data['uid'][:16]}..., phone={data['phone']}")
else:
    print(f"  FAILED: {reg_result[:200]}")

# 4. 用错误的验证码测试（新手机号）
phone2 = "13000002222"
cmd = f"curl -s -X POST http://127.0.0.1:8090/v1/user/sms/registercode -H 'Content-Type: application/json' -d '{{\"phone\":\"{phone2}\"}}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
stdout.read()  # 消耗结果

cmd = f"curl -s -X POST http://127.0.0.1:8090/v1/user/register -H 'Content-Type: application/json' -d '{{\"zone\":\"0086\",\"phone\":\"{phone2}\",\"code\":\"654321\",\"password\":\"test123456\"}}'"
stdin, stdout, stderr = ssh.exec_command(cmd)
reg_result2 = stdout.read().decode()
print("\nRegister with wrong code:")
data2 = json.loads(reg_result2)
if "msg" in data2:
    print(f"  CORRECTLY REJECTED: {data2['msg']}")
else:
    print(f"  UNEXPECTED SUCCESS: {reg_result2[:200]}")

ssh.close()
