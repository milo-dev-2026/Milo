#!/usr/bin/env python3
"""Find exact API path used by admin panel for message sending"""

import paramiko
import base64
import json

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Decode the payload from the log to understand the message format
    print("=== Decode payload from log ===")
    payload_b64 = "eyJjb250ZW50IjoiICDmrKLov47kvb/nlKhNaWxvflxu6K+35a6J5Y2T55So5oi35Zyo5L2/55So5pe25LiN6KaB5p2A5o6JQVBQ5ZCO5Y+w6L+b56iL77yM5LiN54S25peg5rOV5Y+K5pe25o6l5pS25a6e5pe25raI5oGv77yM5aaC5Zyo5L2/55So5Lit5pyJ5Lu75L2V6Zeu6aKY6K+355WZ6KiA77yBXG7mnKzmrKHnmbvlvZXnmoTkv6Hmga/vvJoxNzIuMTkuMC4xIDIwMjYtMDktMjEgMTg6MzE6NDciLCJ0eXBlIjoxfQ=="
    decoded = base64.b64decode(payload_b64).decode('utf-8')
    print(f"Decoded: {decoded}")
    msg_data = json.loads(decoded)
    print(f"Parsed: {json.dumps(msg_data, indent=2, ensure_ascii=False)}")

    # Search JS for all API patterns
    print("\n=== All JS API patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oE '/api/[a-zA-Z0-9_/]+' | sort -u"
    )
    print(stdout.read().decode())

    # Search JS for message/send related paths
    print("\n=== JS message send patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oE '[\"'/][a-zA-Z0-9_/]*message[a-zA-Z0-9_/]*' | sort -u"
    )
    print(stdout.read().decode())

    # Search JS for "sendmsglist" context
    print("\n=== JS sendmsglist context ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oP '.{0,50}sendmsglist.{0,50}'"
    )
    print(stdout.read().decode())

    # Search JS for "message/send" context
    print("\n=== JS message/send context ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oP '.{0,80}message/send.{0,80}'"
    )
    print(stdout.read().decode())

    # Search for all Vue router paths that contain 'message'
    print("\n=== JS message route patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oP 'path:\"[^\"]*\"' | grep -i message"
    )
    print(stdout.read().decode())

    # Look for the actual API call in JS - search for axios/post/GET patterns
    print("\n=== JS API call patterns ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oP '(post|get|put|delete)\\([\"''][^\"'^]*[\"'']' | head -30"
    )
    print(stdout.read().decode())

    # Look for "sendmsglist" API call
    print("\n=== JS sendmsglist API call ===")
    stdin, stdout, stderr = ssh.exec_command(
        """curl -s http://127.0.0.1:83/static/js/index-3da832da.js 2>&1 | grep -oP '.{0,100}sendmsglist.{0,100}'"""
    )
    print(stdout.read().decode()[:500])

    # Check all chunk JS files
    print("\n=== All JS files ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/ 2>&1 | grep -oE '/static/js/[^\"' ]+'"
    )
    print(stdout.read().decode())

    # Check for chunk files that might have the message API
    print("\n=== Chunk JS files ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaomanager-1 find /usr/share/nginx/html/static/js/ -name '*.js' 2>/dev/null"
    )
    files = stdout.read().decode().strip()
    print(files[:2000])

    ssh.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
