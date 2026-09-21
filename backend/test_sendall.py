#!/usr/bin/env python3
"""Test sendall with to_uids field"""

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

    # Test sendall with to_uids
    print("\n=== sendall with to_uids ===")
    payload = json.dumps({"to_uids": [test_uid], "content": "测试特定用户消息"})
    resp1 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/sendall' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload}' 2>&1"""
    )
    print(f"Response: {resp1[:500]}")

    # Test send with to_uids (not to_uid)
    print("\n=== send with to_uids ===")
    payload2 = json.dumps({"to_uids": [test_uid], "content": "测试send with to_uids"})
    resp2 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload2}' 2>&1"""
    )
    print(f"Response: {resp2[:500]}")

    # Test sendall with uids
    print("\n=== sendall with uids ===")
    payload3 = json.dumps({"uids": [test_uid], "content": "测试sendall with uids"})
    resp3 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/sendall' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload3}' 2>&1"""
    )
    print(f"Response: {resp3[:500]}")

    # Search TangSeng source for the send message struct definition
    print("\n=== TangSeng send struct ===")
    resp4 = run(ssh,
        """docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -A2 'managerSendMsgReq'"""
    )
    print(resp4[:1000])

    # Search for struct field definitions
    print("\n=== struct fields near managerSendMsg ===")
    resp5 = run(ssh,
        """docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -B2 -A2 'managerSendMsg'"""
    )
    print(resp5[:2000])

    # Try with to_uid as string (not list)
    print("\n=== send with to_uid string ===")
    payload6 = json.dumps({"to_uid": test_uid, "content": "测试 to_uid string"})
    resp6 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload6}' 2>&1"""
    )
    print(f"Response: {resp6[:500]}")

    # Try with to_uid as array
    print("\n=== send with to_uid array ===")
    payload7 = json.dumps({"to_uid": [test_uid], "content": "测试 to_uid array"})
    resp7 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload7}' 2>&1"""
    )
    print(f"Response: {resp7[:500]}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
