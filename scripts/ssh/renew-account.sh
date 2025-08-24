#!/bin/bash

today=$(date +%s)
EXPIRED_USERS=()

while IFS=: read -r user _ uid _ _ _ _; do
  [[ "$uid" -lt 1000 || "$user" == "nobody" ]] && continue
  expiry_days=$(grep "^$user:" /etc/shadow | cut -d: -f8)
  if [ -n "$expiry_days" ]; then
    expiry_secs=$((expiry_days * 86400))
    if [ "$expiry_secs" -lt "$today" ]; then
      EXPIRED_USERS+=("$user")
    fi
  fi
done < /etc/passwd

gum format --theme dracula --type markdown "# 🔄 Renew Expired Accounts"

if [ ${#EXPIRED_USERS[@]} -eq 0 ]; then
  gum style --foreground 1 "No expired accounts found."
  echo -e
  gum confirm "Return to menu?" && asx
  exit 0
fi

echo -e
user=$(printf "%s\n" "${EXPIRED_USERS[@]}" | gum choose --height=10 --header="Use SPACE or X to select")
if [ -z "$user" ]; then
  gum style --foreground 1 "No accounts selected. Use SPACE or X to select"
  echo -e
  gum confirm "Return to menu?" && asx
fi

echo -ne "\e[38;5;212m📅 Enter number of days to extend (e.g. 7):\e[0m "
read -r days
if [[ ! "$days" =~ ^[0-9]+$ ]]; then
  gum style --foreground 1 "Invalid number of days."
  echo -e
  gum confirm "Return to menu?" && asx
fi

expire_date=$(date -u -d "+$days days" +%Y-%m-%d)
expire_disp=$(date -u -d "+$days days" '+%d %b %Y')

sudo passwd -u "$user" &>/dev/null
sudo usermod -e "$expire_date" "$user"

gum format --theme dracula --type markdown <<EOF
# ✅ Account Renewed

**👤 Username**    : \`$user\`  
**📅 Days Added**  : \`$days\`  
**⏳ Expires On**  : \`$expire_disp\`
EOF

echo -e
gum confirm "Return to menu?" && asx
