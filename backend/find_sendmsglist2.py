#!/usr/bin/env python3
"""Find the exact API used by sendmsglist page"""

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

    # Get full sendmsglist JS
    content = run(ssh, "docker exec tsdd-tangsengdaodaomanager-1 cat /usr/share/nginx/html/static/js/sendmsglist-ded5d9ff.js 2>&1")
    
    # Find all URL-like patterns
    print("=== sendmsglist API patterns ===")
    urls = re.findall(r'/api/v[0-9]+/[a-zA-Z0-9_/]+', content)
    for u in sorted(set(urls)):
        print(f"  {u}")

    # Find all path-like patterns
    print("\n=== sendmsglist paths ===")
    paths = re.findall(r'["\'](/[a-zA-Z0-9_/]+)["\']', content)
    for p in sorted(set(paths)):
        print(f"  {p}")

    # Find 'post' calls
    print("\n=== POST calls ===")
    posts = re.findall(r'\.post\(["\']([^"\']+)["\']', content)
    for p in sorted(set(posts)):
        print(f"  {p}")

    # Find 'get' calls
    print("\n=== GET calls ===")
    gets = re.findall(r'\.get\(["\']([^"\']+)["\']', content)
    for g in sorted(set(gets)):
        print(f"  {g}")

    # Find 'request' calls
    print("\n=== request calls ===")
    reqs = re.findall(r'request\(["\']([^"\']+)["\']', content)
    for r in sorted(set(reqs)):
        print(f"  {r}")

    # Print a section of the file that mentions 'send' or 'message'
    print("\n=== Sections with 'send' or 'message' ===")
    for m in re.finditer(r'.{0,80}(send|message).{0,80}', content):
        print(f"  {m.group()}")

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
