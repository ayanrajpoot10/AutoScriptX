#!/bin/bash

SERVICE_FILE="/etc/systemd/system/ws-proxy.service"

old_res=$(grep ExecStart "$SERVICE_FILE" | sed -n 's/.*--res "\(.*\)".*/\1/p')

[ -z "$old_res" ] && old_res="Switching Protocols"

new_res=$(echo "$old_res" | gum write --placeholder "Write message to show after http/1.1 101 ")

if [ -z "$new_res" ]; then
    echo "❌ No value entered. Exiting."
    exit 1
fi

escaped_res=$(printf '%s\n' "$new_res" | sed 's/[&/\]/\\&/g' | tr '\n' ' ' | sed 's/ *$//')

sed -i "s|--res \".*\"|--res \"$escaped_res\"|" "$SERVICE_FILE"

systemctl daemon-reexec
systemctl daemon-reload
systemctl restart ws-proxy.service

gum style --foreground 212 "✅ 101 Response Updated:"

gum confirm "Return to menu?" && menu
