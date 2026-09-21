#!/usr/bin/env python3
"""Login to admin and test message send"""

import paramiko
import json

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Login
    print("=== Login ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}' 2>&1"""
    )
    resp = stdout.read().decode().strip()
    print(f"Response: {resp[:2000]}")

    try:
        data = json.loads(resp)
        token = data.get("token", "")
        print(f"\nToken: {token[:80]}...")
        print(f"UID: {data.get('uid', '')}")
        print(f"Name: {data.get('name', '')}")
    except:
        print("Failed to parse JSON")
        # Try to find token in the response
        if "token" in resp.lower():
            import re
            m = re.search(r'"token"\s*:\s*"([^"]+)"', resp)
            if m:
                token = m.group(1)
                print(f"Found token: {token[:80]}...")
        else:
            print("No token found in response")
            token = ""

    if token:
        # Get a test user uid
        print("\n=== Get test user ===")
        stdin, stdout, stderr = ssh.exec_command(
            """docker exec tsdd-mysql-1 mysql -uroot -pAbc123456! -N -e "SELECT uid FROM user WHERE uid != 'u_10000' LIMIT 1" im 2>/dev/null"""
        )
        uid_out = stdout.read().decode().strip()
        uid_lines = [l for l in uid_out.split('\n') if 'Warning' not in l and l.strip()]
        test_uid = uid_lines[0] if uid_lines else ''
        print(f"Test uid: {test_uid}")

        if test_uid:
            # Test message/send with admin token
            print("\n=== Test message/send with admin token ===")
            stdin, stdout, stderr = ssh.exec_command(
                f"""curl -s -X POST 'http://127.0.0.1:83/api/v1/message/send' """
                f"""-H 'Content-Type: application/json' """
                f"""-H 'token: {token}' """
                f"""-d '{{"from_uid":"u_10000","channel_id":"{test_uid}","channel_type":1,"content":"测试系统消息","type":1000}}' 2>&1"""
            )
            print(f"Response: {stdout.read().decode().strip()[:500]}")

            # Also try with different field names
            print("\n=== Test with 'from' field ===")
            stdin, stdout, stderr = ssh.exec_command(
                f"""curl -s -X POST 'http://127.0.0.1:83/api/v1/message/send' """
                f"""-H 'Content-Type: application/json' """
                f"""-H 'token: {token}' """
                f"""-d '{{"from":"u_10000","to":"{test_uid}","channel_id":"{test_uid}","channel_type":1,"content":"测试系统消息2","type":1000}}' 2>&1"""
            )
            print(f"Response: {stdout.read().decode().strip()[:500]}")

            # Try without from_uid (let the admin token user be the sender)
            print("\n=== Test without from_uid ===")
            stdin, stdout, stderr = ssh.exec_command(
                f"""curl -s -X POST 'http://127.0.0.1:83/api/v1/message/send' """
                f"""-H 'Content-Type: application/json' """
                f"""-H 'token: {token}' """
                f"""-d '{{"channel_id":"{test_uid}","channel_type":1,"content":"测试系统消息3","type":1000}}' 2>&1"""
            )
            print(f"Response: {stdout.read().decode().strip()[:500]}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
