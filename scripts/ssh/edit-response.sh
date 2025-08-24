#!/bin/bash

SERVICE_FILE="/etc/systemd/system/ws-proxy.service"

old_res=$(grep ExecStart "$SERVICE_FILE" | sed -n 's/.*--res "\(.*\)".*/\1/p')

gum format --theme dracula --type markdown "# ✨ Edit 101 Response"

[ -z "$old_res" ] && old_res="Switching Protocols"

new_res=$(echo "$old_res" | gum write --placeholder "Write message to show after http/1.1 101 ")

if [ -z "$new_res" ] || [ "$new_res" = "$old_res" ]; then
    gum style --foreground 1 "No changes detected. Response not updated."
    echo -e
    gum confirm "Return to menu?" && asx
    exit 0
fi

escaped_res=$(printf '%s\n' "$new_res" | sed 's/[&/\]/\\&/g' | tr '\n' ' ' | sed 's/ *$//')

sed -i "s|--res \".*\"|--res \"$escaped_res\"|" "$SERVICE_FILE"

systemctl daemon-reexec
systemctl daemon-reload
systemctl restart ws-proxy.service

gum style --foreground 212 "✅ 101 Response Updated:"

echo -e
gum confirm "Return to menu?" && asx
