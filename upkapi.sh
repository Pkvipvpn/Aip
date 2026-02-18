#!/bin/bash

clear
echo "======================================"
echo "        UPK VIP API INSTALLER"
echo "======================================"

echo "Installing requirements..."
apt update -y
apt install python3 -y

mkdir -p /root/vpn_api
cd /root/vpn_api

echo "Creating menu.py..."

cat << 'EOF' > menu.py
import sqlite3
import os
from datetime import datetime, timedelta

DB = "users.db"

def clear():
    os.system("clear")

def banner():
    print(r"""
██╗   ██╗██████╗ ██╗  ██╗
██║   ██║██╔══██╗██║ ██╔╝
██║   ██║██████╔╝█████╔╝ 
██║   ██║██╔═══╝ ██╔═██╗ 
╚██████╔╝██║     ██║  ██╗
 ╚═════╝ ╚═╝     ╚═╝  ╚═╝

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
    print("\nADD USER\n")

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
        print(f"\nUser added. Expire date: {expire_date}")
    except:
        print("\nHWID already exists.")

    conn.close()
    input("\nPress Enter to continue...")

def list_users():
    clear()
    banner()
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, name, hwid, expire FROM users")
    rows = c.fetchall()
    conn.close()

    print("\nUSER LIST\n")
    for row in rows:
        print(f"{row[0]}) {row[1]} | {row[2]} | Expire: {row[3]}")

    input("\nPress Enter to continue...")

def main_menu():
    while True:
        clear()
        banner()
        print("1) Add User")
        print("2) List Users")
        print("3) Exit\n")

        choice = input("Select Option: ")

        if choice == "1":
            add_user()
        elif choice == "2":
            list_users()
        elif choice == "3":
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

echo "======================================"
echo "Installation Complete"
echo "Menu starting..."
echo "======================================"

sleep 2
python3 /root/vpn_api/menu.py
