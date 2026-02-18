from fastapi import FastAPI
import sqlite3
from datetime import datetime

app = FastAPI()
DB="users.db"

@app.get("/")
def get_users():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT name, hwid, expire, status FROM users")
    rows = c.fetchall()
    conn.close()

    result = []

    for row in rows:
        name, hwid, expire, status = row

        if status != "active":
            continue

        try:
            expire_date = datetime.strptime(expire, "%Y-%m-%d")
            days_left = (expire_date - datetime.now()).days
        except:
            days_left = 0

        if days_left < 0:
            days_left = 0

        result.append({
            "Name": name,
            "Key": hwid,
            "Valid": str(days_left)
        })

    return result
