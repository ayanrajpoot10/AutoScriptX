#!/bin/bash

DB_PATH="/etc/x-ui/x-ui.db"
STATE_FILE="/etc/AutoScriptX/xray_paths.txt"
LOCATION_DIR="/etc/nginx/locations"
ADD_SCRIPT="/usr/bin/add-location.sh"


mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"
mkdir -p "$LOCATION_DIR"


process_db() {
  local current=""
  current=$(sqlite3 "$DB_PATH" -json "SELECT port, stream_settings FROM inbounds WHERE enable = 1;" 2>/dev/null)

  if [[ "$current" == *"database is locked"* ]]; then
    sleep 3
    current=$(sqlite3 "$DB_PATH" -json "SELECT port, stream_settings FROM inbounds WHERE enable = 1;" 2>/dev/null)
    if [[ "$current" == *"database is locked"* ]]; then
      return 1
    fi
  fi

  parsed=$(echo "$current" | jq -r '
    .[]? |
    select((.stream_settings | fromjson | .network) == "ws") |
    [
      .port,
      (.stream_settings | fromjson | .wsSettings.path // "")
    ] | join("|")
  ')

  OLD=$(mktemp)
  cp "$STATE_FILE" "$OLD"

  > "$STATE_FILE"

  if [[ -n "$parsed" ]]; then
    while IFS='|' read -r port path; do
      [[ -z "$port" || "$port" == "|" ]] && continue
      key="${port}|${path}"
      echo "$key" >> "$STATE_FILE"

      if ! grep -Fxq "$key" "$OLD"; then
        bash "$ADD_SCRIPT" "$path" "$port" >/dev/null 2>&1
      fi
    done <<< "$parsed"
  fi

  comm -23 <(sort "$OLD") <(sort "$STATE_FILE") | while read -r removed; do
    [[ "$removed" != *"|"* ]] && continue
    port="${removed%%|*}"
    path="${removed#*|}"
    file="$LOCATION_DIR/${path#/}.conf"
    if [[ -f "$file" ]]; then
      rm -f "$file"
    fi
  done

  rm -f "$OLD"
}


while true; do
  inotifywait -qq -e modify,close_write,attrib,move_self "$DB_PATH"
  sleep 3
  process_db
done
