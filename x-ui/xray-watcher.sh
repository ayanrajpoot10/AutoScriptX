#!/bin/bash


DB_PATH="/etc/x-ui/x-ui.db"
STATE_FILE="/var/lib/xray-watcher/seen_paths.txt"
LOCATION_DIR="/etc/nginx/locations"
ADD_SCRIPT="/usr/local/bin/add-location.sh"

mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"
mkdir -p "$LOCATION_DIR"


process_db() {
  local current=""
  current=$(sqlite3 "$DB_PATH" -json "SELECT port, stream_settings FROM inbounds WHERE enable = 1;")
  if [[ "$current" == *"database is locked"* ]]; then
    sleep 3
    current=$(sqlite3 "$DB_PATH" -json "SELECT port, stream_settings FROM inbounds WHERE enable = 1;")
    if [[ "$current" == *"database is locked"* ]]; then
      return 1
    fi
  fi
  [ -z "$current" ] && return 1
  parsed=$(echo "$current" | jq -r '
      .[]? |
      select((.stream_settings | fromjson | .network) == "ws") |
      [
        .port,
        (.stream_settings | fromjson | .wsSettings.path // "")
      ] | join("|")
    ')
  [ $? -ne 0 ] && return 1

  OLD=$(mktemp)
  cp "$STATE_FILE" "$OLD"

  {
    while IFS='|' read -r port path; do
      key="${port}|${path}"
      if [[ -z "$port" || "$key" == "|" ]]; then
        continue
      fi
      if ! grep -Fxq "$key" "$STATE_FILE"; then
        bash "$ADD_SCRIPT" "$path" "$port" >/dev/null 2>&1
      fi
      echo "$key"
    done
  } <<< "$parsed" > "$STATE_FILE"

  comm -23 <(sort "$OLD") <(sort "$STATE_FILE") | while read -r removed; do
      if [[ "$removed" != *"|"* ]]; then
        continue
      fi
      port="${removed%%|*}"
      path="${removed#*|}"
      if [[ -z "$port" || -z "$path" ]]; then
        continue
      fi
      file="$LOCATION_DIR/${path#/}.conf"
      [ -f "$file" ] && rm -f "$file"
  done
  rm -f "$OLD"
}


while true; do
  inotifywait -e modify,close_write,move_self,attrib "$DB_PATH" >/dev/null 2>&1
  process_db
done