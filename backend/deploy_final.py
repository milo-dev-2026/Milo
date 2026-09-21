#!/usr/bin/env python3
"""Deploy fixed app.py to remote server and restart service"""

import paramiko
import os

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"
LOCAL_APP_PY = r"C:\Users\Administrator\Desktop\Milo\backend\app.py"
LOCAL_CONFIG_PY = r"C:\Users\Administrator\Desktop\Milo\backend\config.py"
REMOTE_DIR = "/opt/xianleihuhu-sms"
SERVICE_NAME = "xianleihuhu-sms.service"

def main():
    print(f"=== Connecting to {SERVER} ===")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Step 1: Backup current files
    print("=== Step 1: Backup current files ===")
    stdin, stdout, stderr = ssh.exec_command(f"cp {REMOTE_DIR}/app.py {REMOTE_DIR}/app.py.bak.$(date +%Y%m%d%H%M%S) 2>&1")
    print(f"  Backup app.py: {stdout.read().decode().strip()}")
    stdin, stdout, stderr = ssh.exec_command(f"cp {REMOTE_DIR}/config.py {REMOTE_DIR}/config.py.bak.$(date +%Y%m%d%H%M%S) 2>&1")
    print(f"  Backup config.py: {stdout.read().decode().strip()}")

    # Step 2: Upload fixed files
    print("\n=== Step 2: Upload fixed files ===")
    sftp = ssh.open_sftp()

    print(f"  Uploading app.py ({os.path.getsize(LOCAL_APP_PY)} bytes)...")
    sftp.put(LOCAL_APP_PY, f"{REMOTE_DIR}/app.py")
    print("  app.py uploaded.")

    print(f"  Uploading config.py ({os.path.getsize(LOCAL_CONFIG_PY)} bytes)...")
    sftp.put(LOCAL_CONFIG_PY, f"{REMOTE_DIR}/config.py")
    print("  config.py uploaded.")

    sftp.close()

    # Step 3: Restart service
    print(f"\n=== Step 3: Restart {SERVICE_NAME} ===")
    stdin, stdout, stderr = ssh.exec_command(f"systemctl restart {SERVICE_NAME} 2>&1")
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    print(f"  Restart: {out}{err}")

    import time
    time.sleep(2)

    stdin, stdout, stderr = ssh.exec_command(f"systemctl is-active {SERVICE_NAME} 2>&1")
    status = stdout.read().decode().strip()
    print(f"  Service status: {status}")

    # Step 4: Test the disband endpoint
    print("\n=== Step 4: Test disband endpoint ===")
    # Test with a fake group_no - should get a proper error (not "请求地址不存在")
    stdin, stdout, stderr = ssh.exec_command("curl -s -X POST http://127.0.0.1:5001/v1/groups/testgroup123/disband 2>&1")
    out = stdout.read().decode().strip()
    print(f"  Direct (5001) response: {out[:300]}")

    stdin, stdout, stderr = ssh.exec_command("curl -s -X POST http://127.0.0.1:8090/v1/groups/testgroup123/disband 2>&1")
    out = stdout.read().decode().strip()
    print(f"  Via nginx (8090) response: {out[:300]}")

    # Step 5: Check error log for any issues
    print("\n=== Step 5: Check recent error log ===")
    stdin, stdout, stderr = ssh.exec_command(f"tail -20 {REMOTE_DIR}/error.log 2>&1")
    out = stdout.read().decode().strip()
    print(f"  Recent errors:\n{out}")

    ssh.close()
    print("\n=== Deploy complete ===")

if __name__ == "__main__":
    main()
