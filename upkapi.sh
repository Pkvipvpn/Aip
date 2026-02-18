#!/bin/bash

clear
echo "======================================"
echo "        UPK VIP API INSTALLER"
echo "======================================"

apt update -y
apt install python3 python3-pip -y
pip3 install fastapi uvicorn

mkdir -p /root/vpn_api
cd /root/vpn_api

# remove old database
rm -f users.db

# ---------------- MENU PANEL ----------------
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

def add_user():
    clear(); banner()
    name=input("Name: ")
    hwid=input("HWID: ")
    days=int(input("Expire Days: "))
    expire=(datetime.now()+timedelta(days=days)).strftime("%Y-%m-%d")

    conn=sqlite3.connect(DB)
    c=conn.cursor()
    try:
        c.execute("INSERT INTO users(name,hwid,expire,status) VALUES(?,?,?,?)",
                  (name,hwid,expire,"active"))
        conn.commit()
        print("User added ✔ Expire:",expire)
    except:
        print("HWID already exists")
    conn.close()
    input("Press Enter...")

def list_users():
    clear(); banner()
    conn=sqlite3.connect(DB)
    c=conn.cursor()
    c.execute("SELECT id,name,hwid,expire,status FROM users")
    rows=c.fetchall()
    conn.close()

    for r in rows:
        print(r)
    input("Press Enter...")

def delete_user():
    clear(); banner()
    conn=sqlite3.connect(DB)
    c=conn.cursor()
    c.execute("SELECT id,name,hwid,expire,status FROM users")
    rows=c.fetchall()
    conn.close()

    for r in rows:
        print(r)

    uid=input("Enter ID to delete: ")
    conn=sqlite3.connect(DB)
    c=conn.cursor()
    c.execute("DELETE FROM users WHERE id=?", (uid,))
    conn.commit()
    conn.close()
    print("Deleted")
    input("Press Enter...")

def menu():
    while True:
        clear(); banner()
        print("1) Add User")
        print("2) List Users")
        print("3) Delete User")
        print("4) Exit\n")

        ch=input("Select: ")
        if ch=="1": add_user()
        elif ch=="2": list_users()
        elif ch=="3": delete_user()
        elif ch=="4": break

init_db()
menu()
EOF

# ---------------- API DOWNLOAD ----------------
echo "Downloading API..."
wget -O vpn-api.py https://raw.githubusercontent.com/Pkvipvpn/Aip/refs/heads/main/vpn-api.py

# ---------------- START API ----------------
echo "Starting API..."
pkill -f "uvicorn vpn-api:app"
nohup uvicorn vpn-api:app --host 0.0.0.0 --port 80 > api.log 2>&1 &

# ---------------- COMMANDS ----------------
cat << 'EOF' > /usr/local/bin/upk
#!/bin/bash
python3 /root/vpn_api/menu.py
EOF
chmod +x /usr/local/bin/upk

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
echo "API running on: http://SERVER_IP/"
echo "======================================"

sleep 2
python3 /root/vpn_api/menu.py
