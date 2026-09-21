#!/usr/bin/env python3
"""Find API in message-a13469e4.js"""

import paramiko
import re

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

    # Get message JS chunk
    content = run(ssh, "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/message-a13469e4.js 2>&1")
    
    print(f"File size: {len(content)} chars")
    
    # Find all URL patterns
    print("\n=== API patterns ===")
    urls = re.findall(r'/api/v[0-9]+/[a-zA-Z0-9_/]+', content)
    for u in sorted(set(urls)):
        print(f"  {u}")

    # Find paths
    print("\n=== paths ===")
    paths = re.findall(r'["\'](/[a-zA-Z0-9_/]+)["\']', content)
    for p in sorted(set(paths)):
        print(f"  {p}")

    # Find POST/GET/request calls
    print("\n=== POST calls ===")
    posts = re.findall(r'\.post\(["\']([^"\']+)["\']', content)
    for p in sorted(set(posts)):
        print(f"  {p}")

    print("\n=== GET calls ===")
    gets = re.findall(r'\.get\(["\']([^"\']+)["\']', content)
    for g in sorted(set(gets)):
        print(f"  {g}")

    # Print full content (it's likely small)
    print("\n=== Full content ===")
    print(content[:5000])

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
