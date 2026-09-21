#!/usr/bin/env python3
"""Find the exact API used by sendmsglist page"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Get the sendmsglist JS chunk
    print("=== sendmsglist JS API patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/sendmsglist-ded5d9ff.js 2>&1 | grep -oE '/api/[a-zA-Z0-9_/]+' | sort -u"
    )
    print(stdout.read().decode())

    # Search for all URL patterns in sendmsglist
    print("\n=== sendmsglist URL patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/sendmsglist-ded5d9ff.js 2>&1 | grep -oE 'https?://[^\"' ]+|/[a-zA-Z0-9_/]+' | sort -u | head -30"
    )
    print(stdout.read().decode())

    # Search for 'send' or 'message' in sendmsglist
    print("\n=== sendmsglist send/message patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/sendmsglist-ded5d9ff.js 2>&1 | grep -oP '.{0,60}(send|message).{0,60}' | head -20"
    )
    print(stdout.read().decode())

    # Get the full sendmsglist JS content (might be small)
    print("\n=== Full sendmsglist JS ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/sendmsglist-ded5d9ff.js 2>&1 | head -100"
    )
    content = stdout.read().decode()
    print(content[:5000])

    # Also check the axios config for baseURL
    print("\n=== axios config ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/axios-4fe91515.js 2>&1 | grep -oP '.{0,50}(baseURL|base_url|API_URL|api_url).{0,50}'"
    )
    print(stdout.read().decode())

    # Check the app JS for API config
    print("\n=== app JS API config ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/app-55673b08.js 2>&1 | grep -oP '.{0,50}(baseURL|base_url|API_URL|api_url).{0,50}'"
    )
    print(stdout.read().decode())

    # Check the index JS for API config
    print("\n=== index JS API config ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oP '.{0,50}(baseURL|base_url|API_URL|api_url|VITE_).{0,50}'"
    )
    print(stdout.read().decode())

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
