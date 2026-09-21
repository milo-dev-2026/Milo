#!/usr/bin/env python3
"""Check manager container nginx config"""

import paramiko
import json

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def run(ssh, cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    return stdout.read().decode('utf-8', errors='replace')

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Check nginx config inside manager container
    print("=== Manager nginx config ===")
    print(run(ssh, "docker exec tsdd-tangsengdaodaomanager-1 cat /etc/nginx/nginx.conf 2>&1"))
    
    print("\n=== Manager conf.d ===")
    print(run(ssh, "docker exec tsdd-tangsengdaodaomanager-1 ls /etc/nginx/conf.d/ 2>&1"))
    
    print("\n=== Manager default conf ===")
    print(run(ssh, "docker exec tsdd-tangsengdaodaomanager-1 cat /etc/nginx/conf.d/default.conf 2>&1"))

    # Login to get admin token
    resp = run(ssh,
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}'"""
    )
    data = json.loads(resp.strip())
    admin_token = data.get("token", "")
    
    # Get test user
    uid_resp = run(ssh,
        """docker exec tsdd-mysql-1 mysql -uroot -pAbc123456! -N -e "SELECT uid FROM user WHERE uid != 'u_10000' AND uid != 'admin' LIMIT 1" im 2>/dev/null"""
    )
    uid_lines = [l for l in uid_resp.strip().split('\n') if 'Warning' not in l and l.strip()]
    test_uid = uid_lines[0] if uid_lines else ''

    # Try /manager/message/send directly on TangSeng server (8091)
    print("\n=== Test on TangSeng 8091 ===")
    payload = json.dumps({"sender": "u_10000", "receiver": test_uid, "content": "test"})
    resp1 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload}' 2>&1"""
    )
    print(f"8091 /manager/message/send: {resp1[:500]}")

    # Try on the TangSeng server with /v1/ prefix
    print("\n=== Test /v1/manager/message/send on 8091 ===")
    resp2 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload}' 2>&1"""
    )
    print(f"Response: {resp2[:500]}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
