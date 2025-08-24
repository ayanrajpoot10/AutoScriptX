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

gum format --theme dracula --type markdown <<< "# 🧨 Delete SSH Accounts"

if [ -z "$USER_LIST" ]; then
  gum style --foreground 1 "No SSH Account available to delete."
  echo -e
  gum confirm "Return to menu?" && asx
  exit 1
fi

SEL=$(echo -e "$USER_LIST" | gum choose --height=15 --no-limit --header="Use SPACE or X to select")
if [ -z "$SEL" ]; then
  gum style --foreground 1 "No accounts selected. Use SPACE or X to select"
  echo -e
  gum confirm "Return to menu?" && asx
  exit 0
fi

if ! gum confirm "Delete selected accounts?"; then
  gum format --type markdown <<< "**❎ Cancelled.**"
  echo -e
  gum confirm "Return to menu?" && asx
  exit 0
fi

COUNT=0
while IFS= read -r u; do
  u_clean=$(echo "$u" | sed 's/ (Expired)//g')
  if id "$u_clean" &>/dev/null && sudo userdel "$u_clean" &>/dev/null; then
    ((COUNT++))
  fi
done <<< "$SEL"

gum format --type markdown <<< "# 🧹 $COUNT Account(s) deleted"

echo -e
gum confirm "Return to menu?" && asx
