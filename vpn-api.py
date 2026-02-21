@app.get("/")
def get_users():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT name, hwid, expire, last_seen FROM users")
    rows = c.fetchall()
    conn.close()

    result = []
    current_time = datetime.now()
    for name, hwid, expire, last_seen in rows:
        # Online Status စစ်ဆေးခြင်း
        is_online = "offline"
        if last_seen:
            try:
                last_time = datetime.strptime(last_seen, "%Y-%m-%d %H:%M:%S")
                if (current_time - last_time).total_seconds() < 300:
                    is_online = "online"
            except: pass
        
        result.append({
            "Name": name,
            "Key": hwid,
            "Status": is_online,
            "Valid": expire  # ဒီနေရာမှာ "03-22-2026" စတဲ့ ရက်စွဲအတိအကျ ထွက်လာပါမယ်
        })
    return result
