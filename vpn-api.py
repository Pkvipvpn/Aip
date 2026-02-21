import sqlite3
from fastapi import FastAPI
from datetime import datetime, timedelta
import os

app = FastAPI()

# Database လမ်းကြောင်း (မင်းရဲ့ server ပေါ်က နေရာနဲ့ ကိုက်အောင် ပြင်ပါ)
DB_PATH = "/root/vpn_api/users.db"

def init_db():
    if not os.path.exists(os.path.dirname(DB_PATH)):
        os.makedirs(os.path.dirname(DB_PATH))
    
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    # Table မရှိရင် တည်ဆောက်မယ်
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (name TEXT, hwid TEXT PRIMARY KEY, expire TEXT, status TEXT, last_seen TEXT)''')
    conn.commit()
    conn.close()

# API စဖွင့်တာနဲ့ Database ကို စစ်ဆေးမယ်
init_db()

@app.get("/")
def get_all_users():
    """
    APK UI မှာ ပြဖို့အတွက် User အားလုံးရဲ့ စာရင်းကို ထုတ်ပေးတဲ့ API
    """
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT name, hwid, expire, last_seen FROM users")
    rows = c.fetchall()
    conn.close()

    user_list = []
    current_time = datetime.now()

    for name, hwid, expire, last_seen in rows:
        # ၁။ Online/Offline စစ်ဆေးခြင်း (၅ မိနစ်အတွင်း Ping ရှိမှ Online)
        is_online = "offline"
        if last_seen:
            try:
                last_ping = datetime.strptime(last_seen, "%Y-%m-%d %H:%M:%S")
                if (current_time - last_ping).total_seconds() < 300: # ၅ မိနစ် (၃၀၀ စက္ကန့်)
                    is_online = "online"
            except:
                pass
        
        # ၂။ JSON Format ပြင်ဆင်ခြင်း
        user_list.append({
            "Name": name,
            "Key": hwid,
            "Status": is_online,
            "Valid": expire  # ဒီနေရာမှာ ရက်စွဲ (ဥပမာ- 03-22-2026) ပဲ ထွက်မယ်
        })
    
    return user_list

@app.get("/ping/{hwid}")
def update_heartbeat(hwid: str):
    """
    APK ဘက်ကနေ Online ဖြစ်နေကြောင်း သတင်းပို့တဲ့ (Ping) API
    """
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # User ရှိမရှိ အရင်စစ်ပြီးမှ last_seen ကို Update လုပ်မယ်
    c.execute("UPDATE users SET last_seen = ? WHERE hwid = ?", (now_str, hwid))
    conn.commit()
    conn.close()
    
    return {"status": "success", "last_seen": now_str}

# --- Panel ကနေ User ထည့်တဲ့အခါ သုံးဖို့ Helper (Option) ---
# ဒါက မင်း Panel ကနေလှမ်းခေါ်ရင် ရက်စွဲကို တစ်ခါတည်း တွက်ပေးမှာ
@app.get("/add_user")
def add_user(name: str, hwid: str, days: int):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    # ယနေ့ကစပြီး ရက်ပေါင်း (days) ကိုပေါင်းပြီး Expire Date တွက်မယ်
    exp_date = (datetime.now() + timedelta(days=days)).strftime("%m-%d-%Y")
    
    try:
        c.execute("INSERT OR REPLACE INTO users (name, hwid, expire) VALUES (?, ?, ?)", 
                  (name, hwid, exp_date))
        conn.commit()
        msg = f"User {name} added/updated until {exp_date}"
    except Exception as e:
        msg = str(e)
    
    conn.close()
    return {"message": msg}
