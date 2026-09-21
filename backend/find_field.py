#!/usr/bin/env python3
"""Find correct field name by searching TangSeng binary"""

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

    # Search TangSeng binary for the field name near "接受者ID不能为空"
    print("=== Search binary for field name ===")
    resp = run(ssh,
        """docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -B5 -A5 '接受者ID' | head -30"""
    )
    print(resp)

    # Search for json tags related to message send
    print("\n=== Search for json tags ===")
    resp2 = run(ssh,
        """docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -i 'receiver\\|reciever\\|to_uid\\|sender' | head -20"""
    )
    print(resp2)

    # Search for the manager message send struct
    print("\n=== Search for message send struct ===")
    resp3 = run(ssh,
        """docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -i 'manager.*message\\|message.*manager' | head -20"""
    )
    print(resp3)

    # Try to find the bind struct - TangSeng uses gin framework
    # Look for json binding tags
    print("\n=== Search for binding/json tags ===")
    resp4 = run(ssh,
        """docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -E 'json:"[a-z_]+"' | grep -i 'receiver\\|reciev\\|to\\|uid\\|sender\\|content' | head -30"""
    )
    print(resp4)

    # Try the sendall endpoint to see what fields it needs
    print("\n=== Test sendall ===")
    admin_resp = run(ssh,
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}'"""
    )
    admin_token = json.loads(admin_resp.strip()).get("token", "")
    
    payload = json.dumps({"content": "test message"})
    resp5 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/sendall' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload}' 2>&1"""
    )
    print(f"sendall: {resp5[:500]}")

    # Try with uid_list
    payload2 = json.dumps({"uid_list": ["06448fc919214f0b8615710d40910382"], "content": "test"})
    resp6 = run(ssh,
        f"""curl -s -X POST 'http://127.0.0.1:8091/v1/manager/message/sendall' """
        f"""-H 'Content-Type: application/json' """
        f"""-H 'token: {admin_token}' """
        f"""-d '{payload2}' 2>&1"""
    )
    print(f"sendall uid_list: {resp6[:500]}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
