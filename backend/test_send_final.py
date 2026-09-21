#!/usr/bin/env python3
"""Test the correct message send API"""

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

    # Login
    resp = run(ssh,
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}'"""
    )
    admin_token = json.loads(resp.strip()).get("token", "")
    print(f"Admin token: {admin_token}")

    # Get test user
    uid_resp = run(ssh,
        """docker exec tsdd-mysql-1 mysql -uroot -pAbc123456! -N -e "SELECT uid FROM user WHERE uid != 'u_10000' AND uid != 'admin' LIMIT 1" im 2>/dev/null"""
    )
    uid_lines = [l for l in uid_resp.strip().split('\n') if 'Warning' not in l and l.strip()]
    test_uid = uid_lines[0] if uid_lines else ''
    print(f"Test uid: {test_uid}")

    # Test with receiver field
    print("\n=== Test v1/manager/message/send with receiver ===")
    payload = json.dumps({"sender": "u_10000", "receiver": test_uid, "content": "测试系统消息"})
    resp1 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload}' 2>&1"""
    )
    print(f"Response: {resp1[:500]}")

    # Test with receiver_uid
    print("\n=== Test with receiver_uid ===")
    payload2 = json.dumps({"receiver_uid": test_uid, "content": "测试2"})
    resp2 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload2}' 2>&1"""
    )
    print(f"Response: {resp2[:500]}")

    # Test with uid + content
    print("\n=== Test with uid ===")
    payload3 = json.dumps({"uid": test_uid, "content": "测试3"})
    resp3 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload3}' 2>&1"""
    )
    print(f"Response: {resp3[:500]}")

    # Test with to_uid
    print("\n=== Test with to_uid ===")
    payload4 = json.dumps({"to_uid": test_uid, "content": "测试4"})
    resp4 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload4}' 2>&1"""
    )
    print(f"Response: {resp4[:500]}")

    # Test with receiver + sender + content + type
    print("\n=== Test with all fields ===")
    payload5 = json.dumps({
        "sender": "u_10000",
        "receiver": test_uid,
        "content": "测试5",
        "type": 1
    })
    resp5 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload5}' 2>&1"""
    )
    print(f"Response: {resp5[:500]}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
