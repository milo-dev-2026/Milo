#!/usr/bin/env python3
"""Check TangSeng admin manager API"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Check TangSeng manager container
    print("=== Manager container info ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 ls /home/ 2>&1"
    )
    print(stdout.read().decode())

    # Check manager binary for API routes
    print("=== Manager API routes (message/send) ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 strings /home/manager 2>/dev/null | grep -i 'message/send\\|sendmsg\\|send_msg\\|/message' | head -20"
    )
    print(stdout.read().decode())

    # Check manager config
    print("=== Manager config ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /home/configs/config.yaml 2>/dev/null || "
        "docker exec tsdd-tangsengdaodaomanager-1 cat /home/configs/tsdd.yaml 2>/dev/null || "
        "docker exec tsdd-tangsengdaodaomanager-1 find /home -name '*.yaml' -o -name '*.yml' 2>/dev/null"
    )
    print(stdout.read().decode()[:5000])

    # Check manager API - try common admin API paths
    print("\n=== Test admin API paths ===")
    admin_paths = [
        "/api/v1/message/send",
        "/v1/message/send",
        "/api/message/send",
        "/api/v1/system/message",
        "/manager/api/v1/message/send",
        "/manager/v1/message/send",
    ]
    for path in admin_paths:
        stdin, stdout, stderr = ssh.exec_command(
            f"curl -s -o /dev/null -w '%{{http_code}}' -X POST http://127.0.0.1:83{path} 2>&1"
        )
        code = stdout.read().decode().strip()
        if code != "404":
            print(f"  {path}: {code}")

    # Check manager API - look for all routes
    print("\n=== Manager binary route patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 strings /home/manager 2>/dev/null | grep -E '^/(api|v1|manager)' | head -50"
    )
    print(stdout.read().decode())

    # Check manager binary for login/auth
    print("\n=== Manager auth ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 strings /home/manager 2>/dev/null | grep -i 'login\\|token\\|admin\\|pwd\\|password' | head -30"
    )
    print(stdout.read().decode())

    # Check nginx config for port 83
    print("\n=== Nginx config for port 83 ===")
    stdin, stdout, stderr = ssh.exec_command(
        "cat /etc/nginx/nginx.conf 2>&1 | grep -A5 'listen.*83' ; "
        "grep -r '83' /etc/nginx/ 2>&1 | head -10"
    )
    print(stdout.read().decode())

    # Try to login to admin panel
    print("\n=== Try admin login ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -s -X POST http://127.0.0.1:83/api/v1/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"123456"}' 2>&1"""
    )
    print(stdout.read().decode()[:500])

    stdin, stdout, stderr = ssh.exec_command(
        """curl -s -X POST http://127.0.0.1:83/v1/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"123456"}' 2>&1"""
    )
    print(stdout.read().decode()[:500])

    stdin, stdout, stderr = ssh.exec_command(
        """curl -s -X POST http://127.0.0.1:83/api/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"123456"}' 2>&1"""
    )
    print(stdout.read().decode()[:500])

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
