#!/bin/bash

# ဖန်သားပြင်ကို ရှင်းလင်းခြင်း
clear
echo "======================================"
echo "    UPK VIP API (ONLINE STATUS VER)"
echo "======================================"

# လိုအပ်တာတွေ Install လုပ်ခြင်း
apt update -y
apt install python3 python3-pip sqlite3 -y
python3 -m pip install --upgrade pip
python3 -m pip install fastapi uvicorn

# Folder ဆောက်ခြင်း
mkdir -p /root/vpn_api
cd /root/vpn_api

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
   UPK VIP API - STATUS MONITOR
    """)

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    # last_seen column ကို အသစ်ထည့်ထားသည်
    c.execute("""CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT, 
        hwid TEXT UNIQUE, 
        expire TEXT, 
        status TEXT,
        last_seen TEXT)""")
    conn.commit()
    conn.close()

def add_user():
    clear(); banner()
    print("--- Add New User ---")
    name = input("Name: ").strip()
    hwid = input("HWID: ").strip()
    if not name or not hwid:
        print("\n❌ Error: Name/HWID လိုအပ်သည်။")
        input("Press Enter..."); return
    try:
        days = int(input("Expire Days (default 30): ") or "30")
    except: days = 30
        
    expire = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    try:
        c.execute("INSERT INTO users(name, hwid, expire, status) VALUES(?,?,?,?)", 
                  (name, hwid, expire, "active"))
        conn.commit()
        print(f"\n✅ User '{name}' added!")
    except sqlite3.IntegrityError:
        print(f"\n❌ Error: HWID '{hwid}' ရှိပြီးသားဖြစ်သည်။")
    finally: conn.close()
    input("\nPress Enter...")

def list_users():
    clear(); banner()
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT id, name, hwid, last_seen FROM users")
    rows = c.fetchall()
    conn.close()
    
    current_time = datetime.now()
    print(f"{'No':<3} | {'Name':<12} | {'HWID':<15} | {'Status'}")
    print("-" * 50)
    for r in rows:
        status_icon = "🔴 Offline"
        if r[3]: # last_seen ရှိလျှင်
            try:
                last_time = datetime.strptime(r[3], "%Y-%m-%d %H:%M:%S")
                # ၅ မိနစ်အတွင်း signal ရှိလျှင် Online ဟုသတ်မှတ်
                if (current_time - last_time).total_seconds() < 300:
                    status_icon = "🟢 Online"
            except: pass
        print(f"{r[0]:<3} | {r[1]:<12} | {r[2]:<15} | {status_icon}")
    input("\nPress Enter...")

def delete_user():
    clear(); banner()
    uid = input("Enter User ID to delete: ")
    conn = sqlite3.connect(DB); c = conn.cursor()
    c.execute("DELETE FROM users WHERE id=?", (uid,))
    conn.commit(); conn.close()
    print("Deleted ✔"); input("Press Enter...")

def menu():
    init_db()
    while True:
        clear(); banner()
        print("1) Add User\n2) List Users\n3) Delete User\n4) Exit\n")
        ch = input("Select: ")
        if ch == "1": add_user()
        elif ch == "2": list_users()
        elif ch == "3": delete_user()
        elif ch == "4": break

if __name__ == "__main__":
    menu()
EOF

# ---------------- API SETUP ----------------
cat << 'EOF' > vpn-api.py
from fastapi import FastAPI
import sqlite3
from datetime import datetime

app = FastAPI()
DB = "/root/vpn_api/users.db"

# --- User ဆီက Online Signal လက်ခံရန် (Heartbeat) ---
@app.get("/ping/{hwid}")
def ping_user(hwid: str):
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    c.execute("UPDATE users SET last_seen = ? WHERE hwid = ?", (now, hwid))
    conn.commit()
    conn.close()
    return {"status": "alive", "time": now}

# --- API JSON Output ---
@app.get("/")
def get_users():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT name, hwid, expire, status, last_seen FROM users")
    rows = c.fetchall()
    conn.close()

    result = []
    current_time = datetime.now()

    for name, hwid, expire, status, last_seen in rows:
        if status != "active": continue
        
        is_online = "offline"
        if last_seen:
            try:
                last_time = datetime.strptime(last_seen, "%Y-%m-%d %H:%M:%S")
                if (current_time - last_time).total_seconds() < 300:
                    is_online = "online"
            except: pass

        try:
            exp_date = datetime.strptime(expire, "%Y-%m-%d")
            days_left = (exp_date - current_time).days + 1
            if days_left < 0: days_left = 0
        except: days_left = 0

        result.append({
            "Name": name,
            "Key": hwid,
            "Valid": str(days_left),
            "Status": is_online
        })
    return result
EOF

# ---------------- START API ----------------
pkill -f "uvicorn"
nohup python3 -m uvicorn vpn-api:app --host 0.0.0.0 --port 80 > api.log 2>&1 &

# ---------------- COMMANDS ----------------
cat << 'EOF' > /usr/local/bin/upk
#!/bin/bash
python3 /root/vpn_api/menu.py
EOF
chmod +x /usr/local/bin/upk

echo "✅ အဆင့်မြှင့်တင်မှု အောင်မြင်သည်။"
echo "Command: upk"
sleep 2
python3 /root/vpn_api/menu.py
