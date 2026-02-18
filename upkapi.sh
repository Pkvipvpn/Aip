#!/bin/bash

clear
echo "======================================"
echo "        UPK VIP API INSTALLER"
echo "======================================"

echo "Updating system..."
apt update -y

echo "Installing Python..."
apt install python3 python3-pip -y

echo "Creating project folder..."
mkdir -p /root/vpn_api
cd /root/vpn_api

echo "Creating menu.py..."

cat << 'EOF' > menu.py
import sqlite3
from datetime import datetime
import os

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

def pause():
    input("\nPress Enter to continue...")

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

def print_table(rows, headers):
    widths = [len(h)+2 for h in headers]
    for row in rows:
        for i, col in enumerate(row):
            widths[i] = max(widths[i], len(str(col))+2)

    def line():
        print("+" + "+".join("-"*w for w in widths) + "+")

    def row_print(row):
        print("|" + "|".join(str(col).center(widths[i]) for i, col in enumerate(row)) + "|")

    line()
    row_print(headers)
    line()
    for r in rows:
        row_print(r)
    line()

def list_users():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT name, hwid, expire, status FROM users")
    data = c.fetchall()
    conn.close()

    if not data:
        print("No users found.")
        return []

    rows = []
    for i, row in enumerate(data, start=1):
        rows.append((i,) + row)

    headers = [" No ", " Name ", " HWID ", " Expire ", " Status "]
    print_table(rows, headers)
    return data

def add_user():
    clear()
    banner()
    print("\nADD USER\n")

    name = input("Name (optional): ")
    hwid = input("HWID: ")
    expire = input("Expire (YYYY-MM-DD): ")

    conn = sqlite3.connect(DB)
    c = conn.cursor()

    try:
        c.execute("INSERT INTO users (name, hwid, expire, status) VALUES (?, ?, ?, ?)",
                  (name, hwid, expire, "active"))
        conn.commit()
        print("\nUser added successfully.")
    except:
        print("\nHWID already exists.")

    conn.close()
    pause()

def delete_user():
    clear()
    banner()
    print("\nDELETE USER\n")

    users = list_users()
    if not users:
        pause()
        return

    try:
        choice = int(input("\nEnter number to delete: "))
        hwid = users[choice-1][1]

        conn = sqlite3.connect(DB)
        c = conn.cursor()
        c.execute("DELETE FROM users WHERE hwid=?", (hwid,))
        conn.commit()
        conn.close()

        print("User deleted.")
    except:
        print("Invalid selection.")

    pause()

def main_menu():
    while True:
        clear()
        banner()
        print("1) Add User")
        print("2) Delete User")
        print("3) List Users")
        print("4) Exit\n")

        choice = input("Select Option: ")

        if choice == "1":
            add_user()
        elif choice == "2":
            delete_user()
        elif choice == "3":
            clear()
            banner()
            list_users()
            pause()
        elif choice == "4":
            break

init_db()
main_menu()
EOF

echo "Setting alias upk..."

if ! grep -q "alias upk=" ~/.bashrc; then
echo "alias upk='python3 /root/vpn_api/menu.py'" >> ~/.bashrc
fi

source ~/.bashrc

echo "======================================"
echo "Installation Complete"
echo "Type: upk"
echo "======================================"
