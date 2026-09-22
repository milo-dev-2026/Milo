#!/usr/bin/env python3
"""Verify 后羿's profile data across MySQL and WuKongIM."""

import paramiko
import json

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

TARGET_UID = "06448fc919214f0b8615710d40910382"


def run_cmd(ssh, cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='replace').strip()
    err = stderr.read().decode('utf-8', errors='replace').strip()
    return out, err


def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # 1. MySQL user table
    print("=== MySQL: user table (im database) ===")
    out, _ = run_cmd(ssh,
        f'docker exec tsdd-mysql-1 mysql --default-character-set=utf8mb4 '
        f'-uroot -pAbc123456! -N -e '
        f'"SELECT uid, name, short_no, username, nickname FROM user WHERE uid=\'{TARGET_UID}\'" '
        f'im 2>/dev/null')
    print(f"uid | name | short_no | username | nickname")
    print(out)
    print()

    # 2. Search by short_no=888 (simulating what the app does)
    print("=== MySQL: search by short_no='888' (app search flow) ===")
    out, _ = run_cmd(ssh,
        f'docker exec tsdd-mysql-1 mysql --default-character-set=utf8mb4 '
        f'-uroot -pAbc123456! -N -e '
        f'"SELECT uid, name, short_no, username FROM user WHERE short_no=\'888\'" '
        f'im 2>/dev/null')
    print(f"uid | name | short_no | username")
    print(out)
    print()

    # 3. Check WuKongIM user data via API
    print("=== WuKongIM: get user info via API ===")
    # First get admin token
    out, _ = run_cmd(ssh,
        """curl -s -X POST 'http://127.0.0.1:83/api/v1/user/login' """
        """-H 'Content-Type: application/json' """
        """-d '{"username":"superAdmin","password":"admin1234567"}' 2>&1""")
    try:
        data = json.loads(out)
        admin_token = data.get("token", "")
        print(f"Admin token: {admin_token[:20]}...")
    except:
        print(f"Login response: {out}")
        admin_token = ""
    print()

    # Get user info from WuKongIM
    if admin_token:
        print(f"=== WuKongIM: get user {TARGET_UID} ===")
        out, _ = run_cmd(ssh,
            f"""curl -s 'http://127.0.0.1:83/api/v1/user/{TARGET_UID}' """
            f"""-H 'token: {admin_token}' 2>&1""")
        try:
            data = json.loads(out)
            print(json.dumps(data, ensure_ascii=False, indent=2))
        except:
            print(out)
        print()

        # Also try the TangSeng API to search by short_no
        print("=== TangSeng API: search user by '888' ===")
        out, _ = run_cmd(ssh,
            f"""curl -s 'http://127.0.0.1:83/api/v1/user/search?keyword=888' """
            f"""-H 'token: {admin_token}' 2>&1""")
        try:
            data = json.loads(out)
            print(json.dumps(data, ensure_ascii=False, indent=2))
        except:
            print(out)

    # 4. Check if there's a short_no field in WuKongIM's user table too
    print("\n=== MySQL: check WuKongIM user table ===")
    out, _ = run_cmd(ssh,
        f'docker exec tsdd-mysql-1 mysql --default-character-set=utf8mb4 '
        f'-uroot -pAbc123456! -N -e '
        f'"SHOW TABLES" im 2>/dev/null')
    tables = out.split('\n') if out else []
    print(f"Tables in 'im' database: {', '.join(tables[:20])}")
    print()

    # Check if there's a separate `user` table with short_no
    print("=== MySQL: check all columns in user table ===")
    out, _ = run_cmd(ssh,
        f'docker exec tsdd-mysql-1 mysql --default-character-set=utf8mb4 '
        f'-uroot -pAbc123456! -N -e '
        f'"DESCRIBE user" im 2>/dev/null')
    print(out)

    ssh.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
