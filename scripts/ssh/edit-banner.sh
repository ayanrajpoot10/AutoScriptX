#!/bin/bash

BANNER_FILE="/etc/AutoScriptX/banner"

sudo cp "$BANNER_FILE" "${BANNER_FILE}.bak"

if [ -s "$BANNER_FILE" ]; then
    CURRENT_CONTENT=$(cat "$BANNER_FILE")
else
    CURRENT_CONTENT="# Enter your new SSH banner message here"
fi

NEW_BANNER=$(echo "$CURRENT_CONTENT" | gum write --width 60 --height 15 --placeholder "Edit SSH Banner")

gum confirm "Do you want to save this as your new SSH banner?" && {
    echo "$NEW_BANNER" | sudo tee "$BANNER_FILE" > /dev/null
    echo "✅ Banner updated successfully!"
} || {
    echo "❎ Cancelled. No changes were made."
}

gum confirm "Return to menu?" && menu
