#!/usr/bin/env python3
"""Find WuKongIM config and correct API"""

import paramiko
import json
import base64

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Find WuKongIM config file
    print("=== WuKongIM config files ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-wukongim-1 find / -name '*.yaml' -o -name '*.yml' -o -name '*.conf' 2>/dev/null | head -20"
    )
    print(stdout.read().decode())

    # Check /home directory
    print("\n=== WuKongIM /home ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-wukongim-1 ls -la /home/ 2>&1"
    )
    print(stdout.read().decode())

    # Check WuKongIM binary/config
    print("\n=== WuKongIM env ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-wukongim-1 env 2>&1 | grep -i 'api\\|token\\|mode\\|addr'"
    )
    print(stdout.read().decode())

    # Check WuKongIM logs for API info
    print("\n=== WuKongIM logs ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker logs tsdd-wukongim-1 2>&1 | grep -i 'api\\|listen\\|server\\|mode\\|start' | tail -20"
    )
    print(stdout.read().decode())

    # Check what ports WuKongIM is listening on
    print("\n=== WuKongIM ports ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-wukongim-1 ss -tlnp 2>/dev/null || docker exec tsdd-wukongim-1 netstat -tlnp 2>/dev/null"
    )
    print(stdout.read().decode())

    # Try WuKongIM API on port 5100 with various paths
    print("\n=== Test WuKongIM API paths ===")
    test_uid = "06448fc919214f0b8615710d40910382"
    payload_json = json.dumps({"type": 1000, "content": "测试消息"}, ensure_ascii=False)
    payload_b64 = base64.b64encode(payload_json.encode('utf-8')).decode('utf-8')

    paths_and_payloads = [
        # /api/v1/messages/send (standard WuKongIM)
        ("/api/v1/messages/send", {
            "header": {"no_persist": 0, "red_dot": 1, "sync_once": 0},
            "from_uid": "u_10000",
            "channel_id": test_uid,
            "channel_type": 1,
            "payload": payload_b64
        }),
        # Try with from instead of from_uid
        ("/api/v1/messages/send", {
            "from": "u_10000",
            "channel_id": test_uid,
            "channel_type": 1,
            "payload": payload_b64
        }),
        # Try /api/messages/send
        ("/api/messages/send", {
            "from_uid": "u_10000",
            "channel_id": test_uid,
            "channel_type": 1,
            "payload": payload_b64
        }),
        # Try /v1/messages/send
        ("/v1/messages/send", {
            "from_uid": "u_10000",
            "channel_id": test_uid,
            "channel_type": 1,
            "payload": payload_b64
        }),
    ]

    # Get admin token
    stdin, stdout, stderr = ssh.exec_command(
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}'"""
    )
    admin_token = json.loads(stdout.read().decode().strip()).get("token", "")

    # Also try without auth, with API key
    # Check docker-compose for WuKongIM API key
    print("\n=== Docker compose ===")
    stdin, stdout, stderr = ssh.exec_command(
        "find / -name 'docker-compose*' -path '*/tsdd*' 2>/dev/null | head -5"
    )
    compose_files = stdout.read().decode().strip()
    print(f"Compose files: {compose_files}")
    if compose_files:
        compose_file = compose_files.split('\n')[0]
        stdin, stdout, stderr = ssh.exec_command(f"cat {compose_file}")
        content = stdout.read().decode()
        # Look for WuKongIM section
        if 'wukongim' in content.lower() or 'wkim' in content.lower():
            print("WuKongIM section found")
        print(content[:5000])

    # Try with verbose curl to see what's happening
    print("\n=== Verbose test WuKongIM API ===")
    stdin, stdout, stderr = ssh.exec_command(
        f"""curl -sv -X POST 'http://127.0.0.1:5100/api/v1/messages/send' """
        f"""-H 'Content-Type: application/json' """
        f"""-d '{json.dumps(paths_and_payloads[0][1])}' 2>&1"""
    )
    print(stdout.read().decode()[:2000])

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
