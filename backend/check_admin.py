#!/usr/bin/env python3
"""Check admin panel at port 83"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Check what's running on port 83
    print("=== Port 83 service ===")
    stdin, stdout, stderr = ssh.exec_command("curl -s -I http://127.0.0.1:83/ 2>&1")
    print(stdout.read().decode())

    # Check nginx config for port 83
    print("\n=== Nginx config for port 83 ===")
    stdin, stdout, stderr = ssh.exec_command("grep -r 'listen.*83' /etc/nginx/ 2>&1 | head -10")
    print(stdout.read().decode())

    # Check all nginx configs
    print("\n=== Nginx configs ===")
    stdin, stdout, stderr = ssh.exec_command("ls /etc/nginx/conf.d/ 2>&1")
    print(stdout.read().decode())

    # Check docker containers for admin panel
    print("\n=== Docker containers ===")
    stdin, stdout, stderr = ssh.exec_command("docker ps --format '{{.Names}} {{.Ports}}' 2>&1")
    print(stdout.read().decode())

    # Check what TangSeng admin panel is
    print("\n=== TangSeng admin ===")
    stdin, stdout, stderr = ssh.exec_command(
        "docker exec tsdd-tangsengdaodaoserver-1 strings /home/app 2>/dev/null | grep -i 'admin\\|manager\\|dashboard\\|web' | head -20"
    )
    print(stdout.read().decode())

    # Try to access the admin panel
    print("\n=== Admin panel content ===")
    stdin, stdout, stderr = ssh.exec_command("curl -s http://127.0.0.1:83/ 2>&1 | head -50")
    print(stdout.read().decode())

    # Check TangSeng admin API
    print("\n=== TangSeng admin API ===")
    stdin, stdout, stderr = ssh.exec_command(
        "curl -s http://127.0.0.1:83/api/ 2>&1; "
        "echo '---'; "
        "curl -s http://127.0.0.1:83/v1/ 2>&1"
    )
    print(stdout.read().decode())

    ssh.close()
    print("Done.")

if __name__ == "__main__":
    main()
