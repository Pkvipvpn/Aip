#!/bin/bash

# ဖန်သားပြင်ကို ရှင်းလင်းခြင်း
clear
echo "======================================"
echo "      UPK VIP API INSTALLER (FIXED)"
echo "======================================"

# လိုအပ်တာတွေ Install လုပ်ခြင်း
apt update -y
apt install python3 python3-pip sqlite3 -y
python3 -m pip install --upgrade pip
python3 -m pip install fastapi uvicorn requests

# Folder ဆောက်ခြင်း
mkdir -p /root/vpn_api
cd /root/vpn_api

# မှတ်ချက် - rm -f users.db ကို ဖျက်လိုက်ပါပြီ (User ဟောင်းတွေ မပျောက်စေရန်)

# ---------------- MENU PANEL ----------------
cat << 'EOF' > menu.py
import sqlite3
import os
from datetime import datetime, timedelta

DB = "/root/vpn_api/users.db"

def clear():
    os.system("clear")

def banner():
    print(r"""
 ██╗ ██╗██████╗ ██╗ ██╗
 ██║ ██║██╔══██╗██║ ██╔╝
 ██║ ██║██████╔╝█████╔╝ 
 ██║ ██║██╔═══╝ ██╔═██╗ 
 ╚██████╔╝██║     ██║  ██╗
  ╚═════╝ ╚═╝     ╚═╝  ╚═╝
   UPK VIP API USER PANEL
    """)

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT, 
        hwid TEXT UNIQUE, 
        expire TEXT, 
        status TEXT)""")
    conn.commit()
    conn.close()

def add_user():
    clear()
    banner()
    print("--- Add New User ---")
    name = input("Name: ").strip()
    hwid = input("HWID: ").strip()
    
    if not name or not hwid:
        print("\n❌ Name and HWID cannot be empty!")
        input("Press Enter...")
        return

    try:
        days = int(input("Expire Days (default 30): ") or "30")
    except ValueError:
        days = 30
        
    expire = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")
    
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    try:
        c.execute("INSERT INTO users(name, hwid, expire, status) VALUES(?,?,?,?)", 
                  (name, hwid, expire, "active"))
        conn.commit()
        print(f"\n✅ User '{name}' added! Expire: {expire}")
    except sqlite3.IntegrityError:
        print(f"\n❌ Error: HWID '{hwid}' already exists in database!")
    finally:
        conn.close()
    input("\nPress Enter...")

def list_users():
    clear()
    banner()
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, name, hwid, expire, status FROM users")
    rows = c.fetchall()
    conn.close()
    
    print(f"{'No':<3} | {'Name':<12} | {'HWID':<15} | {'Expire':<12} | {'Status'}")
    print("-" * 60)
    for r in rows:
        print(f"{r[0]:<3} | {r[1]:<12} | {r[2]:<15} | {r[3]:<12} | {r[4]}")
    input("\nPress Enter...")

def delete_user():
    clear()
    banner()
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, name, hwid FROM users")
    rows = c.fetchall()
    if not rows:
        print("No users found.")
        conn.close()
        input("Press Enter...")
        return

    for r in rows:
        print(f"{r[0]}) {r[1]} ({r[2]})")
    
    uid = input("\nEnter User ID to delete: ")
    c.execute("DELETE FROM users WHERE id=?", (uid,))
    conn.commit()
    conn.close()
    print("Deleted ✔")
    input("Press Enter...")

def menu():
    init_db()
    while True:
        clear()
        banner()
        print("1) Add User")
        print("2) List Users")
        print("3) Delete User")
        print("4) Exit\n")
        ch = input("Select: ")
        if ch == "1": add_user()
        elif ch == "2": list_users()
        elif ch == "3": delete_user()
        elif ch == "4": break

if __name__ == "__main__":
    menu()
EOF

# ---------------- API SETUP ----------------
echo "Setting up API..."
# vpn-api.py ကို အသစ်ပြန်ရေးမယ် (ရက်တွက်ပုံ ပြင်ထားသည်)
cat << 'EOF' > vpn-api.py
from fastapi import FastAPI
import sqlite3
from datetime import datetime

app = FastAPI()
DB = "/root/vpn_api/users.db"

@app.get("/")
def get_users():
    try:
        conn = sqlite3.connect(DB)
        c = conn.cursor()
        c.execute("SELECT name, hwid, expire, status FROM users")
        rows = c.fetchall()
        conn.close()
    except:
        return []

    result = []
    current_time = datetime.now()

    for name, hwid, expire, status in rows:
        if status != "active":
            continue
        try:
            expire_date = datetime.strptime(expire, "%Y-%m-%d")
            # ရက်ကျန်တွက်ချက်မှု (ဒီနေ့ပါအကျုံးဝင်စေရန်)
            days_left = (expire_date - current_time).days + 1
            if days_left < 0: days_left = 0
        except:
            days_left = 0

        result.append({
            "Name": name,
            "Key": hwid,
            "Valid": str(days_left)
        })
    return result
EOF

# ---------------- START API ----------------
echo "Restarting API Service..."
pkill -f "uvicorn"
nohup python3 -m uvicorn vpn-api:app --host 0.0.0.0 --port 80 > api.log 2>&1 &

# ---------------- SHORTCUT COMMANDS ----------------
cat << 'EOF' > /usr/local/bin/upk
#!/bin/bash
python3 /root/vpn_api/menu.py
EOF
chmod +x /usr/local/bin/upk

cat << 'EOF' > /usr/local/bin/upk-reset
#!/bin/bash
read -p "Are you sure you want to reset everything? (y/n): " confirm
if [ "$confirm" == "y" ]; then
    rm -rf /root/vpn_api
    echo "Panel removed."
fi
EOF
chmod +x /usr/local/bin/upk-reset

echo "======================================"
echo "✅ Installation Complete!"
echo "Commands:"
echo "  upk       -> Open User Panel"
echo "  upk-reset -> Remove Database & Files"
echo ""
echo "API URL: http://$(hostname -I | awk '{print $1}')/"
echo "======================================"
sleep 2
python3 /root/vpn_api/menu.py
