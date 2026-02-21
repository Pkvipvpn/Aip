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



@app.get("/add_user")
def add_user(name: str, hwid: str, days: int):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    # လက်ရှိအချိန်ကနေ ရက်ပေါင်း (days) ကိုပေါင်းပြီး ရက်စွဲတွက်မယ်
    # ဥပမာ- ယနေ့ကစပြီး ရက် ၃၀ ဆိုရင် "03-23-2026" လို့ ထွက်လာမယ်
    expire_date = (datetime.now() + timedelta(days=days)).strftime("%m-%d-%Y")
    
    c.execute("INSERT OR REPLACE INTO users (name, hwid, expire) VALUES (?, ?, ?)", 
              (name, hwid, expire_date))
    conn.commit()
    conn.close()
    return {"status": "success", "expire": expire_date}

@app.get("/")
def get_all_users():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT name, hwid, expire, last_seen FROM users")
    rows = c.fetchall()
    conn.close()

    user_list = []
    for name, hwid, expire, last_seen in rows:
        # Online status logic ...
        user_list.append({
            "Name": name,
            "Key": hwid,
            "Status": "online" if is_online else "offline",
            "Valid": expire  # အခုဆိုရင် "30" မဟုတ်ဘဲ "03-23-2026" ဖြစ်သွားပါပြီ
        })
    return user_list
