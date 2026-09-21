#!/usr/bin/env python3
"""Login to TangSeng admin and test message send"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Test login with various API paths
    login_paths = [
        "/api/v1/login",
        "/api/login",
        "/v1/login",
        "/api/v1/user/login",
        "/api/v1/admin/login",
        "/api/v1/manager/login",
    ]

    for path in login_paths:
        print(f"\n=== POST {path} ===")
        stdin, stdout, stderr = ssh.exec_command(
            f"""curl -s -X POST 'http://127.0.0.1:83{path}' """
            """-H 'Content-Type: application/json' """
            """-d '{"username":"superAdmin","password":"admin1234567"}' 2>&1"""
        )
        resp = stdout.read().decode().strip()
        print(f"  Response: {resp[:500]}")
        if "token" in resp.lower() or "200" in resp:
            print("  ^^^ SUCCESS!")
            break

    # Also try GET /api/v1/login to see what's expected
    print("\n=== GET /api/v1/login ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -s http://127.0.0.1:83/api/v1/login 2>&1"""
    )
    print(stdout.read().decode()[:500])

    # Try the TangSeng manager API directly on the manager container
    print("\n=== Manager container direct API ===")
    # The manager container is on port 83 (nginx proxy to 80)
    # Let's check if there's a separate API port
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 netstat -tlnp 2>/dev/null || "
        "docker exec tsdd-tangsengdaodaomanager-1 ss -tlnp 2>/dev/null"
    )
    print(stdout.read().decode())

    # Check nginx config for port 83 proxy
    print("\n=== Nginx config ===")
    stdin, stdout, stderr = ssh.exec_command(
        "cat /etc/nginx/nginx.conf 2>&1"
    )
    print(stdout.read().decode()[:3000])

    # Check all nginx conf files
    print("\n=== Nginx conf.d files ===")
    stdin, stdout, stderr = ssh.exec_command(
        "cat /etc/nginx/conf.d/*.conf 2>&1"
    )
    print(stdout.read().decode()[:5000])

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
