#!/bin/bash

DOMAIN_FILE="/etc/AutoScriptX/domain"
PORT_INFO="/etc/AutoScriptX/port-info.json"

gum format --theme dracula --type markdown "# 🛠️ Create SSH Account"

echo -ne "\e[38;5;212m  👤 Username:\e[0m "
read -r username
echo -ne "\e[38;5;212m  🔑 Password:\e[0m "
read -r password
echo -ne "\e[38;5;212m  📅 Expired (days):\e[0m "
read -r expire_days

public_ip=$(curl -s ifconfig.me)
domain=$(cat "$DOMAIN_FILE")
expire_date=$(date -d "$expire_days days" +"%Y-%m-%d")

useradd -e "$expire_date" -s /bin/false -M "$username"
echo -e "$password\n$password" | passwd "$username" &>/dev/null
expire_date_str=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)

gum format --theme dracula --type markdown <<EOF
# ✅ SSH Account Created

**👤 Username**    : \`$username\`  
**🔑 Password**    : \`$password\`  
**📅 Expires On**  : $expire_date_str  
**🌐 Public IP**   : $public_ip  
**📡 Host**        : $domain  

# 📦 Ports

- SSH WS      : 80
- SSH SSL WS  : 443
- SSL/TLS     : 443
- SQUID       : 8080
- UDPGW       : 7200,7300

# 🧪 Payloads

**WSS Payload**
\`\`\`
GET wss://example.com HTTP/1.1[crlf]
Host: $domain[crlf]
Upgrade: websocket[crlf][crlf]
\`\`\`

**WS Payload**  
\`\`\`
GET / HTTP/1.1[crlf]
Host: $domain[crlf]
Upgrade: websocket[crlf][crlf]
\`\`\`
EOF

gum confirm "Return to menu?" && asx
