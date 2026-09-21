#!/usr/bin/env python3
"""Check server state to find deployment path"""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

def main():
    print(f"=== Connecting to {SERVER} ===")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    commands = [
        # Find app.py anywhere on the server
        ("Find app.py", "find / -name 'app.py' -path '*/leihuhu*' 2>/dev/null; find / -name 'app.py' -path '*/sms*' 2>/dev/null; find /opt /home /var/www /srv -name 'app.py' 2>/dev/null"),
        # Check systemd services
        ("Systemd services", "systemctl list-units --type=service --all 2>/dev/null | grep -i 'leihuhu\\|sms\\|flask\\|gunicorn\\|python'"),
        # Check running python processes
        ("Python processes", "ps aux | grep -i 'python\\|gunicorn\\|flask' | grep -v grep"),
        # Check what's listening on ports 8090/8091
        ("Listening ports", "ss -tlnp | grep -E '809[01]' 2>/dev/null || netstat -tlnp | grep -E '809[01]' 2>/dev/null"),
        # Check nginx config files
        ("Nginx configs", "ls -la /etc/nginx/conf.d/ 2>/dev/null; echo '---'; cat /etc/nginx/conf.d/*.conf 2>/dev/null | head -80"),
        # Check supervisor
        ("Supervisor", "supervisorctl status 2>/dev/null || echo 'no supervisor'"),
        # Check common deployment directories
        ("Common dirs", "ls -la /opt/ 2>/dev/null; echo '---'; ls -la /home/ 2>/dev/null; echo '---'; ls -la /srv/ 2>/dev/null"),
        # Check docker
        ("Docker", "docker ps 2>/dev/null || echo 'no docker'"),
    ]

    for label, cmd in commands:
        print(f"=== {label} ===")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        if out:
            print(out)
        if err:
            print(f"  stderr: {err}")
        print()

    ssh.close()

if __name__ == "__main__":
    main()
