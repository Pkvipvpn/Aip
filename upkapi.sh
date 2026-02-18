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
import os

DB = "users.db"

def clear():
    os.system("clear")

def banner():
    print(r"""
      
    
    
     
       
         

        UPK VIP API PANEL
""")

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

def main_menu():
    while True:
        clear()
        banner()
        print("1) Add User")
        print("2) Exit\n")

        choice = input("Select Option: ")

        if choice == "1":
            name = input("Name: ")
            hwid = input("HWID: ")
            expire = input("Expire: ")

            conn = sqlite3.connect(DB)
            c = conn.cursor()
            c.execute("INSERT INTO users (name, hwid, expire, status) VALUES (?, ?, ?, ?)",
                      (name, hwid, expire, "active"))
            conn.commit()
            conn.close()

            input("User added. Press Enter...")
        elif choice == "2":
            break

init_db()
main_menu()
EOF

echo "Creating upk command..."

cat << 'EOF' > /usr/local/bin/upk
#!/bin/bash
python3 /root/vpn_api/menu.py
EOF

chmod +x /usr/local/bin/upk

echo "======================================"
echo "Installation Complete"
echo "Type: upk"
echo "======================================"
