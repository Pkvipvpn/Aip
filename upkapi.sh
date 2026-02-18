#!/bin/bash

clear
echo "======================================"
echo "        UPK VIP API INSTALLER"
echo "======================================"

apt update -y
apt install python3 -y

mkdir -p /root/vpn_api
cd /root/vpn_api

echo "Rebuilding menu.py..."

cat << 'EOF' > menu.py
import sqlite3
import os
from datetime import datetime, timedelta

DB = "users.db"

def clear():
    os.system("clear")

def banner():
    print(r"""
UPK VIP API PANEL
""")

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT,
                  hwid TEXT UNIQUE,
                  expire TEXT,
                  status TEXT)''')
    conn.commit()
    conn.close()

def add_user():
    clear()
    banner()

    name = input("Name: ")
    hwid = input("HWID: ")
    days = int(input("Expire Days (30/60/90): "))

    expire_date = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")

    conn = sqlite3.connect(DB)
    c = conn.cursor()

    try:
        c.execute("INSERT INTO users (name, hwid, expire, status) VALUES (?, ?, ?, ?)",
                  (name, hwid, expire_date, "active"))
        conn.commit()
        print("Expire date:", expire_date)
    except:
        print("HWID already exists")

    conn.close()
    input("Press Enter...")

def list_users():
    clear()
    banner()

    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, name, hwid, expire, status FROM users")
    rows = c.fetchall()
    conn.close()

    for r in rows:
        print(r)

    input("\nPress Enter...")

def delete_user():
    clear()
    banner()

    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, name, hwid, expire FROM users")
    rows = c.fetchall()
    conn.close()

    for r in rows:
        print(r)

    uid = input("\nEnter ID to delete: ")

    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("DELETE FROM users WHERE id=?", (uid,))
    conn.commit()
    conn.close()

    print("User deleted")
    input("Press Enter...")

def main_menu():
    while True:
        clear()
        banner()
        print("1) Add User")
        print("2) List Users")
        print("3) Delete User")
        print("4) Exit\n")

        choice = input("Select Option: ")

        if choice == "1":
            add_user()
        elif choice == "2":
            list_users()
        elif choice == "3":
            delete_user()
        elif choice == "4":
            break

init_db()
main_menu()
EOF

echo "Creating upk command..."

cat << 'EOF' > /usr/local/bin/upk
#!/bin/bash
python3 /root/vpn_api/menu.py
EOF

chmod +x /usr/local/bin/upk

# Reset script
cat << 'EOF' > /usr/local/bin/upk-reset
#!/bin/bash
rm -rf /root/vpn_api
echo "All files removed. Run installer again."
EOF

chmod +x /usr/local/bin/upk-reset

echo "======================================"
echo "Installation Complete"
echo "Commands:"
echo "upk        -> open panel"
echo "upk-reset  -> reset all files"
echo "======================================"

sleep 2
python3 /root/vpn_api/menu.py
