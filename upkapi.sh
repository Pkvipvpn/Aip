#!/bin/bash

clear
echo "======================================"
echo "        UPK VIP API INSTALLER"
echo "======================================"

apt update -y
apt install python3 -y

mkdir -p /root/vpn_api
cd /root/vpn_api

# remove old database
rm -f users.db

cat << 'EOF' > menu.py
import sqlite3
import os
from datetime import datetime, timedelta

DB="users.db"

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

      UPK VIP API USER PANEL
""")

def init_db():
    conn=sqlite3.connect(DB)
    c=conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        hwid TEXT UNIQUE,
        expire TEXT,
        status TEXT)""")
    conn.commit()
    conn.close()

def table(rows):
    print("+----+------------+----------------------+------------+--------+")
    print("| No | Name       | HWID                 | Expire     | Status |")
    print("+----+------------+----------------------+------------+--------+")
    for r in rows:
        print(f"| {str(r[0]).ljust(2)} | {str(r[1]).ljust(10)} | {str(r[2]).ljust(20)} | {str(r[3]).ljust(10)} | {str(r[4]).ljust(6)} |")
    print("+----+------------+----------------------+------------+--------+")

def add_user():
    clear(); banner()
    print("\nADD USER\n")

    name=input("Name: ")
    hwid=input("HWID: ")
    days=int(input("Expire Days (30/60/90): "))

    expire=(datetime.now()+timedelta(days=days)).strftime("%Y-%m-%d")

    conn=sqlite3.connect(DB)
    c=conn.cursor()
    try:
        c.execute("INSERT INTO users(name,hwid,expire,status) VALUES(?,?,?,?)",
                  (name,hwid,expire,"active"))
        conn.commit()
        print("\nUser added ✔")
        print("Expire:",expire)
    except:
        print("\nHWID already exists")
    conn.close()
    input("\nPress Enter...")

def list_users():
    clear(); banner()
    conn=sqlite3.connect(DB)
    c=conn.cursor()
    c.execute("SELECT id,name,hwid,expire,status FROM users")
    rows=c.fetchall()
    conn.close()

    if rows:
        table(rows)
    else:
        print("No users found.")
    input("\nPress Enter...")

def delete_user():
    clear(); banner()
    conn=sqlite3.connect(DB)
    c=conn.cursor()
    c.execute("SELECT id,name,hwid,expire,status FROM users")
    rows=c.fetchall()
    conn.close()

    if not rows:
        print("No users.")
        input("\nPress Enter...")
        return

    table(rows)

    try:
        num=int(input("\nEnter No to delete: "))
        conn=sqlite3.connect(DB)
        c=conn.cursor()
        c.execute("DELETE FROM users WHERE id=?", (num,))
        conn.commit()
        conn.close()
        print("User deleted ✔")
    except:
        print("Invalid selection")

    input("\nPress Enter...")

def menu():
    while True:
        clear(); banner()
        print("1) Add User")
        print("2) List Users")
        print("3) Delete User")
        print("4) Exit\n")

        ch=input("Select Option: ")

        if ch=="1":
            add_user()
        elif ch=="2":
            list_users()
        elif ch=="3":
            delete_user()
        elif ch=="4":
            break

init_db()
menu()
EOF

# command
cat << 'EOF' > /usr/local/bin/upk
#!/bin/bash
python3 /root/vpn_api/menu.py
EOF
chmod +x /usr/local/bin/upk

# reset command
cat << 'EOF' > /usr/local/bin/upk-reset
#!/bin/bash
rm -rf /root/vpn_api
echo "Panel removed. Run installer again."
EOF
chmod +x /usr/local/bin/upk-reset

echo "======================================"
echo "Installation Complete"
echo "Commands:"
echo "upk        -> open panel"
echo "upk-reset  -> reset panel"
echo "======================================"

sleep 2
python3 /root/vpn_api/menu.py
