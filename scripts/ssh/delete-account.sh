#!/bin/bash


today=$(date +%s)

USER_LIST=$(awk -F: '$3 > 1000 && $1 != "nobody" { print $1 }' /etc/passwd | while read -r u; do
  expiry_days=$(grep "^$u:" /etc/shadow | cut -d: -f8)
  if [ -n "$expiry_days" ]; then
    expiry_secs=$((expiry_days * 86400))
    if [ "$expiry_secs" -lt "$today" ]; then
      echo "$u (Expired)"
      continue
    fi
  fi
  echo "$u"
done)

gum format --theme dracula --type markdown <<< "# 🧨 Delete SSH Users"
if [ -z "$USER_LIST" ]; then
  gum format --type markdown <<< "**❌ No SSH users available to delete.**"
  exit 0
fi
SEL=$(echo -e "$USER_LIST" | gum choose --height=15 --no-limit --header="Select users to delete")
[ -z "$SEL" ] && gum format --type markdown <<< "**❌ No users selected.**" && exit 0

gum confirm "Delete selected users?" || { gum format --type markdown <<< "**❎ Cancelled.**"; exit 0; }

COUNT=0
while IFS= read -r u; do
  u_clean=$(echo "$u" | sed 's/ (Expired)//g')
  if id "$u_clean" &>/dev/null && sudo userdel "$u_clean" &>/dev/null; then
    ((COUNT++))
  fi
done <<< "$SEL"

gum format --type markdown <<< "## 🧹 $COUNT Account(s) deleted**"

gum confirm "Return to menu?" && menu
