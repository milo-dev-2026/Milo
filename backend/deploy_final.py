#!/usr/bin/env python3
"""Deploy app.py to server and restart"""

import paramiko
import os

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"
LOCAL_FILE = r"C:\Users\Administrator\Desktop\Milo\backend\app.py"
REMOTE_FILE = "/opt/xianleihuhu-sms/app.py"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.")

    # Upload app.py
    print(f"Uploading app.py ({os.path.getsize(LOCAL_FILE)} bytes)...")
    sftp = ssh.open_sftp()
    sftp.put(LOCAL_FILE, REMOTE_FILE)
    sftp.close()
    print("Uploaded.")

    # Restart service
    print("Restarting xianleihuhu-sms.service...")
    stdin, stdout, stderr = ssh.exec_command("systemctl restart xianleihuhu-sms.service && sleep 2 && systemctl is-active xianleihuhu-sms.service")
    print(f"Status: {stdout.read().decode().strip()}")

    # Check error log
    print("\nRecent error log:")
    stdin, stdout, stderr = ssh.exec_command("tail -5 /opt/xianleihuhu-sms/error.log 2>&1")
    print(stdout.read().decode())

    ssh.close()
    print("Done.")

if __name__ == "__main__":
    main()
