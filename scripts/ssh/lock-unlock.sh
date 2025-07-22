#!/bin/bash


gum format --theme gracula --type markdown "🔐 Toggle Account Status"

users=$(awk -F: '$3 > 1000 && $1 != "nobody" {print $1}' /etc/passwd)

entries=()
while IFS= read -r user; do
  passwd_field=$(grep "^$user:" /etc/shadow | cut -d: -f2)
  if [[ "$passwd_field" =~ ^! ]]; then
    entries+=("🔒 $user")
  else
    entries+=("🔓 $user")
  fi
done <<< "$users"

if [[ ${#entries[@]} -eq 0 ]]; then
  gum style --foreground 1 "❌ No regular user accounts found."
  exit 1
fi

selected=$(printf "%s\n" "${entries[@]}" | gum choose --height 20 --no-limit)
[[ -z "$selected" ]] && exit 0

user=$(echo "$selected" | awk '{print $2}')
status=$(echo "$selected" | awk '{print $1}')

if [[ "$status" == "🔒" ]]; then
  if gum confirm "🔓 Unlock user '$user'?"; then
    usermod -U "$user" && \
    gum style --foreground 2 "✅ '$user' has been unlocked." || \
    gum style --foreground 1 "❌ Failed to unlock '$user'."
  fi
else
  if gum confirm "🔒 Lock user '$user'?"; then
    usermod -L "$user" && \
    gum style --foreground 3 "🔒 '$user' has been locked." || \
    gum style --foreground 1 "❌ Failed to lock '$user'."
  fi
fi

gum confirm "Return to menu?" && menu
