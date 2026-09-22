#!/usr/bin/env python3
"""Update 后羿's short_no from WAKMUW3VBV to 888 using uid directly."""

import paramiko

SERVER = "43.133.39.170"
USERNAME = "root"
PASSWORD = "Lixin123"

TARGET_UID = "06448fc919214f0b8615710d40910382"
NEW_SHORT_NO = "888"


def run_sql(ssh, sql):
    cmd = f'docker exec tsdd-mysql-1 mysql --default-character-set=utf8mb4 -uroot -pAbc123456! -N -e "{sql}" im 2>/dev/null'
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='replace').strip()
    return out


def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USERNAME, password=PASSWORD, timeout=15)
    print("SSH connected.\n")

    # Step 1: Show current user info
    print("=== Current user info ===")
    out = run_sql(ssh, f"SELECT uid, name, short_no FROM user WHERE uid='{TARGET_UID}'")
    print(out)
    print()

    # Step 2: Check if '888' is already taken
    print("=== Check if short_no '888' is available ===")
    out = run_sql(ssh, f"SELECT uid, name FROM user WHERE short_no='{NEW_SHORT_NO}'")
    if out:
        print(f"WARNING: '888' already taken by: {out}")
        ssh.close()
        return
    print("OK: '888' is available.\n")

    # Step 3: Update short_no to '888'
    print(f"=== Updating short_no to '{NEW_SHORT_NO}' ===")
    out = run_sql(ssh, f"UPDATE user SET short_no='{NEW_SHORT_NO}' WHERE uid='{TARGET_UID}'")
    print("Update executed.\n")

    # Step 4: Verify
    print("=== Verification ===")
    out = run_sql(ssh, f"SELECT uid, name, short_no FROM user WHERE uid='{TARGET_UID}'")
    print(f"Result: {out}")

    # Also test search by short_no '888'
    print("\n=== Test: search user by short_no '888' ===")
    out = run_sql(ssh, f"SELECT uid, name, short_no FROM user WHERE short_no='{NEW_SHORT_NO}'")
    print(f"Search result: {out}")

    ssh.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
