#!/usr/bin/env python3
"""Test WuKongIM direct API for sending messages as u_10000"""

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

    # Get admin token from TangSeng
    print("=== Get admin token ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}' 2>&1"""
    )
    resp = stdout.read().decode().strip()
    data = json.loads(resp)
    admin_token = data.get("token", "")
    print(f"Admin token: {admin_token}")

    # Get test user
    stdin, stdout, stderr = ssh.exec_command(
        """docker exec tsdd-mysql-1 mysql -uroot -pAbc123456! -N -e "SELECT uid FROM user WHERE uid != 'u_10000' AND uid != 'admin' LIMIT 1" im 2>/dev/null"""
    )
    uid_out = stdout.read().decode().strip()
    uid_lines = [l for l in uid_out.split('\n') if 'Warning' not in l and l.strip()]
    test_uid = uid_lines[0] if uid_lines else ''
    print(f"Test uid: {test_uid}")

    # Check WuKongIM API
    print("\n=== WuKongIM API endpoints ===")
    # WuKongIM HTTP API is on port 5100
    # Try /api/v1/messages/send
    stdin, stdout, stderr = ssh.exec_command(
        f"""curl -s -X POST 'http://127.0.0.1:5100/api/v1/messages/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{{"header":{{"no_persist":0,"red_dot":0,"sync_once":0}},"from_uid":"u_10000","channel_id":"{test_uid}","channel_type":1,"payload":"{{\\"type\\":1000,\\"content\\":\\"测试消息\\"}}"}}' 2>&1"""
    )
    print(f"WuKongIM /api/v1/messages/send: {stdout.read().decode().strip()[:500]}")

    # Try WuKongIM with different payload format
    print("\n=== WuKongIM v2 ===")
    import base64
    payload_json = json.dumps({"type": 1000, "content": "测试系统消息"}, ensure_ascii=False)
    payload_b64 = base64.b64encode(payload_json.encode('utf-8')).decode('utf-8')
    stdin, stdout, stderr = ssh.exec_command(
        f"""curl -s -X POST 'http://127.0.0.1:5100/api/v1/messages/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{{"header":{{"no_persist":0,"red_dot":1,"sync_once":0}},"from_uid":"u_10000","channel_id":"{test_uid}","channel_type":1,"payload":"{payload_b64}"}}' 2>&1"""
    )
    print(f"Response: {stdout.read().decode().strip()[:500]}")

    # Try without token (WuKongIM API might use API key auth)
    print("\n=== WuKongIM without token ===")
    stdin, stdout, stderr = ssh.exec_command(
        f"""curl -s -X POST 'http://127.0.0.1:5100/api/v1/messages/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-d '{{"header":{{"no_persist":0,"red_dot":1,"sync_once":0}},"from_uid":"u_10000","channel_id":"{test_uid}","channel_type":1,"payload":"{payload_b64}"}}' 2>&1"""
    )
    print(f"Response: {stdout.read().decode().strip()[:500]}")

    # Check WuKongIM config for API token
    print("\n=== WuKongIM config ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-wukongim-1 cat /home/wk.yaml 2>/dev/null | head -50"
    )
    print(stdout.read().decode()[:3000])

    # Check WuKongIM manager API
    print("\n=== WuKongIM manager API ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-wukongim-1 cat /home/wk.yaml 2>/dev/null | grep -i 'api\\|token\\|key\\|manager\\|admin'"
    )
    print(stdout.read().decode())

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
