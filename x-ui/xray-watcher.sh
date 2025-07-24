#!/bin/bash

DB_PATH="/etc/x-ui/x-ui.db"
STATE_FILE="/var/lib/xray-watcher/seen_paths.txt"
LOCATION_DIR="/etc/nginx/locations"
ADD_SCRIPT="/usr/local/bin/add-location.sh"

mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"
mkdir -p "$LOCATION_DIR"

current=$(
  sqlite3 "$DB_PATH" -json "SELECT port, stream_settings FROM inbounds WHERE enable = 1;" | \
  jq -r '
    .[] |
    select((.stream_settings | fromjson | .network) == "ws") |
    [
      .port,
      (.stream_settings | fromjson | .wsSettings.path)
    ] | @tsv
  '
)

OLD=$(mktemp)
cp "$STATE_FILE" "$OLD"

echo "$current" | while IFS=$'\t' read -r port path; do
    key="${port}${path}"
    if ! grep -Fxq "$key" "$STATE_FILE"; then
        echo "[+] New account detected: $path $port"
        bash "$ADD_SCRIPT" "$path" "$port"
    fi
    echo "$key"
done > "$STATE_FILE"

comm -23 <(sort "$OLD") <(sort "$STATE_FILE") | while read -r removed; do
    port="${removed%%/*}"
    path="/${removed#${port}}"
    file="$LOCATION_DIR/${path#/}.conf"
    echo "[-] Removing: $file"
    [ -f "$file" ] && rm -f "$file"
done

