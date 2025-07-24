#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root."
    exit 1
fi

BIN_DIR="/usr/local/bin"
SYSTEMD_DIR="/etc/systemd/system"
ADD_LOCATION_DST="$BIN_DIR/add-location.sh"
XRAY_WATCHER_DST="$BIN_DIR/xray-watcher.sh"
SERVICE_DST="$SYSTEMD_DIR/xray-watcher.service"
GITHUB_RAW="https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/master/x-ui"

echo "Installing dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq sqlite3 jq inotify-tools

curl -fsSL "$GITHUB_RAW/add-location.sh" -o "$ADD_LOCATION_DST"
curl -fsSL "$GITHUB_RAW/xray-watcher.sh" -o "$XRAY_WATCHER_DST"
chmod 755 "$ADD_LOCATION_DST" "$XRAY_WATCHER_DST"
curl -fsSL "$GITHUB_RAW/xray-watcher.service" -o "$SERVICE_DST"
chmod 644 "$SERVICE_DST"
systemctl daemon-reload
systemctl enable --now xray-watcher.service

echo "xray-watcher installed and running."
echo "Status:    systemctl status xray-watcher.service"
echo "Logs:      journalctl -u xray-watcher.service"
echo "Uninstall: systemctl disable --now xray-watcher.service && rm -f $ADD_LOCATION_DST $XRAY_WATCHER_DST $SERVICE_DST && systemctl daemon-reload"
