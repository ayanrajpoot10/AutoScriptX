#!/bin/bash


if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root."
    exit 1
fi

echo "Installing dependencies..."
apt-get update
apt-get install -y sqlite3 jq inotify-tools nginx wget


BASE_URL="https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/master/x-ui"
echo "Downloading scripts..."
wget -O /usr/bin/add-location.sh "$BASE_URL/add-location.sh"
wget -O /usr/bin/xui-watcher.sh "$BASE_URL/xui-watcher.sh"
chmod +x /usr/bin/add-location.sh /usr/bin/xui-watcher.sh

mkdir -p /etc/nginx/locations
mkdir -p /etc/AutoScriptX
touch /etc/AutoScriptX/xray_paths.txt

systemctl daemon-reload

echo "Installation Complete"
