#!/bin/bash

blue="\033[1;34m"
green="\033[1;32m"
red="\033[1;31m"
yellow="\033[1;33m"
nc="\033[0m"


log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }


if [ "$(id -u)" -ne 0 ]; then
    log_error "Run as root."
    exit 1
fi


if ! command -v x-ui >/dev/null 2>&1 && ! systemctl list-units --type=service | grep -qE 'x-ui'; then
    log_info "x-ui not found. Installing 3x-ui..."
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
else
    log_success "x-ui is already installed."
fi


log_info "Installing dependencies..."
apt-get update >/dev/null 2>&1
apt-get install -y sqlite3 jq inotify-tools nginx wget >/dev/null 2>&1


BASE_URL="https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/master/x-ui"
log_info "Downloading scripts..."
wget -O /usr/bin/add-location.sh "$BASE_URL/add-location.sh" >/dev/null 2>&1
wget -O /usr/bin/xui-watcher.sh "$BASE_URL/xui-watcher.sh" >/dev/null 2>&1
chmod +x /usr/bin/add-location.sh /usr/bin/xui-watcher.sh >/dev/null 2>&1


log_info "Downloading and installing systemd service..."
wget -O /etc/systemd/system/xui-watcher.service "$BASE_URL/xui-watcher.service" >/dev/null 2>&1


mkdir -p /etc/nginx/locations >/dev/null 2>&1
mkdir -p /etc/AutoScriptX >/dev/null 2>&1
touch /etc/AutoScriptX/xray_paths.txt >/dev/null 2>&1


systemctl daemon-reload >/dev/null 2>&1
systemctl enable xui-watcher.service >/dev/null 2>&1
systemctl restart xui-watcher.service >/dev/null 2>&1


log_success "Installation complete. xui-watcher service is running."
