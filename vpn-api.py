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
    except Exception as e:
        return {"error": str(e)}

    result = []
    current_time = datetime.now()

    for name, hwid, expire, status in rows:
        # Status ကို စစ်ဆေးခြင်း
        if status != "active":
            continue

        try:
            expire_date = datetime.strptime(expire, "%Y-%m-%d")
            # အချိန်ကွာခြားချက်ကို တွက်ချက်ခြင်း
            delta = expire_date - current_time
            days_left = delta.days + 1 # ဒီနေ့ပါအကျုံးဝင်အောင် +1 ထည့်ပေးလေ့ရှိတယ်
        except:
            days_left = 0

        # ရက်ကုန်သွားရင် 0 လို့ ပြမယ်
        if days_left < 0:
            days_left = 0

        result.append({
            "Name": name,
            "Key": hwid,
            "Valid": str(days_left)
        })

    return result
