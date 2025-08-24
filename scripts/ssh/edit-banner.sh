#!/bin/bash

BANNER_FILE="/etc/AutoScriptX/banner"

sudo cp "$BANNER_FILE" "${BANNER_FILE}.bak"

gum format --theme dracula --type markdown "# 🪄 Edit SSH Banner"

if [ -s "$BANNER_FILE" ]; then
    CURRENT_CONTENT=$(cat "$BANNER_FILE")
else
    CURRENT_CONTENT="# Enter your new SSH banner message here"
fi

NEW_BANNER=$(echo "$CURRENT_CONTENT" | gum write --width 60 --height 15 --placeholder "Edit SSH Banner")

if [ -z "$NEW_BANNER" ] || [ "$NEW_BANNER" = "$CURRENT_CONTENT" ]; then
    gum style --foreground 1 "No changes detected. Banner not updated."
else
    gum confirm "Do you want to save this as your new SSH banner?" && {
        echo "$NEW_BANNER" | sudo tee "$BANNER_FILE" > /dev/null
        sudo systemctl restart dropbear >/dev/null 2>&1
        gum style --foreground 2 "✅ Banner updated successfully!"
    } || {
        gum style --foreground 2 "❎ Cancelled. No changes were made."
    }
fi

echo -e
gum confirm "Return to menu?" && asx
