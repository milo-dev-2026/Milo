#!/usr/bin/env python3
"""Test the correct admin message send API"""

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

    # Login to get admin token
    print("=== Login ===")
    resp = run(ssh,
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}'"""
    )
    data = json.loads(resp.strip())
    admin_token = data.get("token", "")
    print(f"Admin token: {admin_token}")

    # Get test user uid
    uid_resp = run(ssh,
        """docker exec tsdd-mysql-1 mysql -uroot -pAbc123456! -N -e "SELECT uid FROM user WHERE uid != 'u_10000' AND uid != 'admin' LIMIT 1" im 2>/dev/null"""
    )
    uid_lines = [l for l in uid_resp.strip().split('\n') if 'Warning' not in l and l.strip()]
    test_uid = uid_lines[0] if uid_lines else ''
    print(f"Test uid: {test_uid}")

    # Test 1: /manager/message/send (POST)
    print("\n=== Test /manager/message/send ===")
    payload = json.dumps({
        "sender": "u_10000",
        "receiver": test_uid,
        "content": "测试系统消息 - 群解散通知"
    })
    resp = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:83/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload}' 2>&1"""
    )
    print(f"Response: {resp[:500]}")

    # Test 2: Try different field names
    print("\n=== Test /manager/message/send v2 ===")
    payload2 = json.dumps({
        "sender_uid": "u_10000",
        "receiver_uid": test_uid,
        "content": "测试2",
        "type": 1
    })
    resp2 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:83/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload2}' 2>&1"""
    )
    print(f"Response: {resp2[:500]}")

    # Test 3: Try with minimal fields
    print("\n=== Test /manager/message/send minimal ===")
    payload3 = json.dumps({
        "content": "测试3"
    })
    resp3 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:83/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload3}' 2>&1"""
    )
    print(f"Response: {resp3[:500]}")

    # Test 4: /manager/message/sendall (POST) - send to all
    print("\n=== Test /manager/message/sendall ===")
    payload4 = json.dumps({
        "content": "测试群发消息"
    })
    resp4 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:83/manager/message/sendall' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload4}' 2>&1"""
    )
    print(f"Response: {resp4[:500]}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
