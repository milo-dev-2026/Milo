#!/usr/bin/env python3
"""Check server logs for disband failure"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Check error log - last 30 lines
    print("=== Recent error log ===")
    stdin, stdout, stderr = ssh.exec_command("tail -30 /opt/xianleihuhu-sms/error.log 2>&1")
    print(stdout.read().decode())

    # Check what version of app.py is deployed
    print("\n=== Deployed disband function ===")
    stdin, stdout, stderr = ssh.exec_command("grep -n 'def disband_group' /opt/xianleihuhu-sms/app.py")
    line_info = stdout.read().decode().strip()
    print(f"Found at: {line_info}")
    if ':' in line_info:
        line_num = int(line_info.split(':')[0])
        stdin, stdout, stderr = ssh.exec_command(f"sed -n '{line_num},{line_num+70}p' /opt/xianleihuhu-sms/app.py")
        print(stdout.read().decode())

    # Check get_current_uid function
    print("\n=== get_current_uid function ===")
    stdin, stdout, stderr = ssh.exec_command("grep -n 'def get_current_uid' /opt/xianleihuhu-sms/app.py")
    uid_info = stdout.read().decode().strip()
    print(f"Found at: {uid_info}")
    if ':' in uid_info:
        uid_line = int(uid_info.split(':')[0])
        stdin, stdout, stderr = ssh.exec_command(f"sed -n '{uid_line},{uid_line+15}p' /opt/xianleihuhu-sms/app.py")
        print(stdout.read().decode())

    # Check access log for disband requests
    print("\n=== Access log for disband ===")
    stdin, stdout, stderr = ssh.exec_command("grep -i 'disband' /opt/xianleihuhu-sms/access.log 2>&1 | tail -10")
    print(stdout.read().decode())

    ssh.close()
    print("Done.")

if __name__ == "__main__":
    main()
