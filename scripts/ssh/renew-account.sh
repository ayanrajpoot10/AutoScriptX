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

if [ ${#EXPIRED_USERS[@]} -eq 0 ]; then
  gum format --type markdown <<< "**✅ No expired users found.**"
  gum confirm "Return to menu?" && menu
fi

gum format --theme dracula --type markdown <<EOF
# 🔄 Renew Expired User

Select an expired user to renew access.
EOF

user=$(printf "%s\n" "${EXPIRED_USERS[@]}" | gum choose --height=10 --header="Select user to renew")
[ -z "$user" ] && gum format --type markdown <<< "**❌ No user selected.**" && exit 1

days=$(gum input --placeholder "Enter number of days to extend (e.g. 7)")
[[ ! "$days" =~ ^[0-9]+$ ]] && gum format --type markdown <<< "**❌ Invalid number of days.**" && exit 1

expire_date=$(date -u -d "+$days days" +%Y-%m-%d)
expire_disp=$(date -u -d "+$days days" '+%d %b %Y')

sudo passwd -u "$user" &>/dev/null
sudo usermod -e "$expire_date" "$user"

gum format --theme dracula --type markdown <<EOF
## ✅ User Renewed

**👤 Username**    : \`$user\`  
**📅 Days Added**  : \`$days\`  
**⏳ Expires On**  : \`$expire_disp\`
EOF

gum confirm "Return to menu?" && menu
