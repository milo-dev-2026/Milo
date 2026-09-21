#!/usr/bin/env python3
"""Deploy backend changes to remote server via SSH"""

import paramiko
import os
import sys
import stat as stat_module

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"
LOCAL_BACKEND = r"C:\Users\Administrator\Desktop\Milo\backend"

REMOTE_APP_DIR = "/opt/leihuhu-sms"
REMOTE_NGINX_CONF = "/etc/nginx/conf.d/xianleihuhu-sms.nginx.conf"

def main():
    print(f"=== Connecting to {SERVER} ===")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.")

    # Step 1: Check current state
    print("\n=== Step 1: Check current server state ===")
    stdin, stdout, stderr = ssh.exec_command(f"ls -la {REMOTE_APP_DIR}/ 2>/dev/null; echo '---'; cat {REMOTE_NGINX_CONF} 2>/dev/null | head -5; echo '---'; systemctl is-active leihuhuhu-sms 2>/dev/null || systemctl is-active leihuhu-sms 2>/dev/null || echo 'service not found'")
    output = stdout.read().decode()
    err = stderr.read().decode()
    print(f"Server state:\n{output}")
    if err:
        print(f"stderr: {err}")

    # Step 2: Upload modified files
    print("\n=== Step 2: Upload modified files ===")
    sftp = ssh.open_sftp()

    files_to_upload = [
        ("app.py", f"{REMOTE_APP_DIR}/app.py"),
        ("config.py", f"{REMOTE_APP_DIR}/config.py"),
        ("xianleihuhu-sms.nginx.conf", "/tmp/xianleihuhu-sms.nginx.conf"),
    ]

    for local_name, remote_path in files_to_upload:
        local_path = os.path.join(LOCAL_BACKEND, local_name)
        if os.path.exists(local_path):
            print(f"  Uploading {local_name} -> {remote_path}")
            sftp.put(local_path, remote_path)
            print(f"  OK: {local_name} uploaded ({os.path.getsize(local_path)} bytes)")
        else:
            print(f"  SKIP: {local_name} not found")

    sftp.close()

    # Step 3: Deploy nginx config and reload
    print("\n=== Step 3: Deploy nginx config ===")
    commands = [
        f"cp /tmp/xianleihuhu-sms.nginx.conf {REMOTE_NGINX_CONF}",
        "nginx -t 2>&1",
        "systemctl reload nginx 2>&1 || nginx -s reload 2>&1",
        "echo 'nginx done'",
    ]
    for cmd in commands:
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        if out:
            print(f"  {cmd}: {out}")
        if err:
            print(f"  {cmd} stderr: {err}")

    # Step 4: Restart backend service
    print("\n=== Step 4: Restart backend service ===")
    commands = [
        # Try different service names
        "systemctl restart leihuhuhu-sms 2>&1 || systemctl restart leihuhu-sms 2>&1 || echo 'systemctl failed'",
        "systemctl is-active leihuhuhu-sms 2>/dev/null || systemctl is-active leihuhu-sms 2>/dev/null || echo 'unknown'",
        # Fallback: check if running via other method
        f"cd {REMOTE_APP_DIR} && supervisorctl restart all 2>&1 || echo 'no supervisor'",
        # Check if it's running as a systemd service
        "systemctl list-units --type=service | grep -i 'leihuhu\\|sms\\|flask' 2>&1 || echo 'no matching service'",
        # Check running processes
        "ps aux | grep -i 'app.py\\|gunicorn\\|flask' | grep -v grep 2>&1 || echo 'no process found'",
    ]
    for cmd in commands:
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        if out:
            print(f"  {cmd}: {out}")
        if err:
            print(f"  {cmd} stderr: {err}")

    # Step 5: Test the disband endpoint
    print("\n=== Step 5: Test disband endpoint ===")
    stdin, stdout, stderr = ssh.exec_command("curl -s -o /dev/null -w '%{http_code}' -X POST http://127.0.0.1:8090/v1/groups/test/disband 2>&1")
    out = stdout.read().decode().strip()
    print(f"  HTTP status code: {out}")

    stdin, stdout, stderr = ssh.exec_command("curl -s -X POST http://127.0.0.1:8090/v1/groups/test/disband 2>&1")
    out = stdout.read().decode().strip()
    print(f"  Response: {out[:200]}")

    # Step 6: Check nginx proxy config
    print("\n=== Step 6: Check nginx routing ===")
    stdin, stdout, stderr = ssh.exec_command(f"cat {REMOTE_NGINX_CONF} 2>&1")
    out = stdout.read().decode().strip()
    print(f"  Nginx config:\n{out}")

    ssh.close()
    print("\n=== Deploy complete ===")

if __name__ == "__main__":
    main()
