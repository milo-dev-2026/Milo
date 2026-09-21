#!/usr/bin/env python3
"""Check TangSeng admin manager - deeper investigation"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # The manager container serves static files on port 83
    # The actual API is likely proxied to the TangSeng server (8091)
    # Let's check what /api/v1/message/send returns
    print("=== Test /api/v1/message/send (POST) ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -sv -X POST 'http://127.0.0.1:83/api/v1/message/send' """
        """-H 'Content-Type: application/json' """
        """-d '{"content":"test","channel_id":"test","channel_type":1}' 2>&1"""
    )
    print(stdout.read().decode()[:1000])

    # Check what /v1/message/send returns with GET (was 405)
    print("\n=== /v1/message/send - check allowed methods ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -sv -X OPTIONS 'http://127.0.0.1:83/v1/message/send' 2>&1"""
    )
    print(stdout.read().decode()[:1000])

    # Check the JS bundle for API paths
    print("\n=== JS bundle API paths ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oE '/api/[a-zA-Z0-9_/]+' | sort -u | head -30"
    )
    print(stdout.read().decode())

    # Check for message-related API in JS
    print("\n=== JS message API paths ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oE '\"[^\"]*message[^\"]*\"' | head -30"
    )
    print(stdout.read().decode())

    # Check for login API in JS
    print("\n=== JS login API ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oE '\"[^\"]*login[^\"]*\"' | head -10"
    )
    print(stdout.read().decode())

    # Check for all API patterns in JS
    print("\n=== All API patterns in JS ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oE '/api/v[0-9]+/[a-zA-Z0-9_/]+' | sort -u | head -50"
    )
    print(stdout.read().decode())

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
