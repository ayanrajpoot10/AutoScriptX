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

echo "Downloading and installing systemd service..."
wget -O /etc/systemd/system/xui-watcher.service "$BASE_URL/xui-watcher.service"

mkdir -p /etc/nginx/locations
mkdir -p /etc/AutoScriptX
touch /etc/AutoScriptX/xray_paths.txt

systemctl daemon-reload
systemctl enable xui-watcher.service
systemctl restart xui-watcher.service

echo "Installation complete. xui-watcher service is running."
