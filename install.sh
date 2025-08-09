#!/bin/bash


green="\033[0;32m"
blue="\033[0;34m"
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m"

BASE_URL="https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/master"


log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    log_error "Run as root."
    exit 1
fi


localip=$(hostname -I | cut -d ' ' -f1)
hostname=$(hostname)
domain_from_etc=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')
[ "$hostname" != "$domain_from_etc" ] && echo "$localip $hostname" >> /etc/hosts


mkdir -p /etc/AutoScriptX
clear
echo "---------------------------"
echo "      VPS DOMAIN SETUP     "
echo "---------------------------"
read -rp "Enter Your Domain: " domain
clear
if [[ -z "$domain" ]]; then
    log_error "Domain cannot be empty."
    exit 1
fi
if echo "$domain" > /etc/AutoScriptX/domain; then
    log_success "Domain saved."
else
    log_error "Failed to save domain."
    exit 1
fi


log_info "Updating system..."
apt update -y > /dev/null 2>&1 && apt dist-upgrade -y > /dev/null 2>&1
if [[ $? -ne 0 ]]; then log_error "System update failed."; exit 1; fi
apt-get purge -y ufw firewalld exim4 samba* apache2* bind9* sendmail* unscd > /dev/null 2>&1 || log_warning "Some packages could not be purged (may not be installed)."
apt autoremove -y > /dev/null 2>&1 && apt autoclean -y > /dev/null 2>&1
log_success "System updated."


log_info "Installing packages..."
apt install -y \
  netfilter-persistent screen curl jq bzip2 gzip vnstat coreutils rsyslog \
  zip unzip net-tools nano lsof shc gnupg dos2unix dirmngr bc \
  stunnel4 nginx dropbear socat xz-utils sshguard > /dev/null 2>&1
if [[ $? -ne 0 ]]; then log_error "Failed to install one or more packages."; exit 1; fi
log_success "Packages installed."


log_info "Installing gum..."
wget -qO- https://github.com/charmbracelet/gum/releases/download/v0.16.2/gum_0.16.2_Linux_x86_64.tar.gz | \
  tar -xz -C /usr/local/bin --strip-components=1 --wildcards '*/gum'
if [[ -f /usr/local/bin/gum ]]; then
  chmod +x /usr/local/bin/gum
  log_success "gum installed."
else
  log_error "Failed to install gum."
  exit 1
fi


log_info "Disabling IPv6..."
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
sysctl --system > /dev/null 2>&1 || log_warning "Failed to reload sysctl settings."
log_success "IPv6 disabled."


log_info "Configuring Dropbear..."
wget -qO /etc/default/dropbear "$BASE_URL/config/dropbear.conf" || log_error "Failed to download dropbear.conf."
chmod 644 /etc/default/dropbear
wget -qO /etc/AutoScriptX/banner "$BASE_URL/config/banner.conf" || log_warning "Failed to download Dropbear banner."
chmod 644 /etc/AutoScriptX/banner
echo -e "/bin/false\n/usr/sbin/nologin" >> /etc/shells
systemctl daemon-reload > /dev/null 2>&1
systemctl enable dropbear > /dev/null 2>&1
systemctl restart dropbear > /dev/null 2>&1 || log_warning "Failed to restart Dropbear."
log_success "Dropbear configured."


log_info "Setting up SSH-WebSocket service..."

# Stop ws-proxy service and remove old binary before reinstall
systemctl stop ws-proxy.service > /dev/null 2>&1 || true
rm -f /usr/local/bin/ws-proxy
wget -O /usr/local/bin/ws-proxy "$BASE_URL/bin/ws-proxy" > /dev/null 2>&1 && chmod +x /usr/local/bin/ws-proxy || log_warning "Failed to install websocket proxy"
wget -O /etc/systemd/system/ws-proxy.service "$BASE_URL/service/systemd/ws-proxy.service" > /dev/null 2>&1 && chmod +x /etc/systemd/system/ws-proxy.service || log_warning "Failed to install websocket proxy service"
systemctl daemon-reload > /dev/null 2>&1
systemctl enable ws-proxy.service > /dev/null 2>&1
systemctl restart ws-proxy.service > /dev/null 2>&1 || log_warning "Failed to restart ws-proxy.service."
log_success "SSH-WebSocket service set up."


log_info "Requesting SSL cert..."

# Clean up previous certs and acme.sh install for idempotency
systemctl stop nginx > /dev/null 2>&1
rm -rf /root/.acme.sh
rm -f /etc/AutoScriptX/cert.crt /etc/AutoScriptX/cert.key
mkdir -p /root/.acme.sh
curl -s https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh || log_error "Failed to download acme.sh."
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade > /dev/null 2>&1
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt > /dev/null 2>&1
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 > /dev/null 2>&1 || log_error "acme.sh certificate issue failed."
/root/.acme.sh/acme.sh --installcert -d "$domain" \
  --fullchainpath /etc/AutoScriptX/cert.crt \
  --keypath /etc/AutoScriptX/cert.key --ecc > /dev/null 2>&1 || log_error "acme.sh certificate install failed."
log_success "SSL cert installed."


log_info "Setting up Nginx..."
rm -f /etc/nginx/{sites-available/default,sites-enabled/default,conf.d/default.conf}
mkdir -p /home/vps/public_html
mkdir -p /etc/systemd/system/nginx.service.d
files=(
  "nginx.conf:/etc/nginx/nginx.conf"
  "reverse-proxy.conf:/etc/nginx/conf.d/reverse-proxy.conf"
  "real_ip_sources.conf:/etc/nginx/conf.d/real_ip_sources.conf"
)
for f in "${files[@]}"; do
    name="${f%%:*}"
    path="${f##*:}"
    wget -qO "$path" "$BASE_URL/config/$name" || log_error "Failed to download $name."
    if [[ "$name" == "reverse-proxy.conf" ]]; then
        sed -i "s/server_name _;/server_name $domain;/" "$path"
    fi
done
systemctl daemon-reload > /dev/null 2>&1
systemctl enable nginx > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1 || log_error "Failed to restart Nginx."
log_success "Nginx set up."


log_info "Setting up BadVPN..."

# Stop all running badvpn-udpgw services and kill processes before replacing binary
for port in 7200 7300; do
  systemctl stop badvpn-udpgw@${port}.service > /dev/null 2>&1 || true
done
pkill -f badvpn-udpgw || true
rm -f /usr/bin/badvpn-udpgw
wget -qO /usr/bin/badvpn-udpgw "$BASE_URL/bin/badvpn-udpgw" || log_error "Failed to download BadVPN."
chmod +x /usr/bin/badvpn-udpgw
wget -qO /etc/systemd/system/badvpn-udpgw@.service "$BASE_URL/service/systemd/badvpn-udpgw@.service" || log_error "Failed to download badvpn-udpgw@.service."
for port in 7200 7300; do
      systemctl enable --now badvpn-udpgw@${port}.service > /dev/null 2>&1 || log_warning "Failed to start badvpn-udpgw@${port}.service."
done
log_success "BadVPN set up."


log_info "Configuring Stunnel..."
wget -qO /etc/stunnel/stunnel.conf "$BASE_URL/config/stunnel.conf" || log_error "Failed to download stunnel.conf."
openssl req -x509 -nodes -days 1095 -newkey rsa:2048 \
  -keyout /etc/stunnel/key.pem -out /etc/stunnel/cert.pem \
  -subj "/C=IN/ST=Maharashtra/L=Mumbai/O=none/OU=none/CN=none/emailAddress=none" > /dev/null 2>&1 || log_error "Failed to generate stunnel certificate."
cat /etc/stunnel/{key.pem,cert.pem} > /etc/stunnel/stunnel.pem
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl enable stunnel4 > /dev/null 2>&1
systemctl restart stunnel4 > /dev/null 2>&1 || log_warning "Failed to restart stunnel4."
log_success "Stunnel configured."


log_info "Configuring SSHGuard..."
systemctl enable sshguard > /dev/null 2>&1
systemctl restart sshguard > /dev/null 2>&1 || log_warning "Failed to restart sshguard."
log_success "SSHGuard configured."


log_info "Applying firewall rules..."
iptables_rules=(
  "get_peers" "announce_peer" "find_node" "BitTorrent"
  "BitTorrent protocol" "peer_id=" ".torrent"
  "announce.php?passkey=" "torrent" "announce" "info_hash"
)
for s in "${iptables_rules[@]}"; do
  iptables -A FORWARD -m string --string "$s" --algo bm -j DROP
done
iptables-save > /etc/iptables.up.rules
netfilter-persistent save > /dev/null 2>&1 && netfilter-persistent reload > /dev/null 2>&1
log_success "Firewall rules applied."


log_info "Installing scripts..."
declare -A script_dirs=(
  [menu]="menu.sh"
  [ssh]="create-account.sh delete-account.sh edit-banner.sh edit-response.sh lock-unlock.sh renew-account.sh"
  [system]="change-domain.sh manage-services.sh system-info.sh clean-expired-accounts.sh"
)
for dir in "${!script_dirs[@]}"; do
  for s in ${script_dirs[$dir]}; do
    base="${s%.sh}"
    wget -qO "/usr/bin/$base" "$BASE_URL/scripts/$dir/$s" > /dev/null 2>&1 || log_warning "Failed to download $s."
    chmod +x "/usr/bin/$base"
  done
done
log_success "Scripts installed."


log_info "Setting up cron jobs..."
wget -qO /etc/cron.d/auto-reboot "$BASE_URL/service/cron/auto-reboot" || log_error "Failed to download auto-reboot."
wget -qO /etc/cron.d/clean-expired-accounts "$BASE_URL/service/cron/clean-expired-accounts" || log_error "Failed to download clean-expired-accounts."
service cron restart > /dev/null 2>&1
log_success "Cron jobs set up."


log_info "Final cleanup..."
chown -R www-data:www-data /home/vps/public_html
history -c && echo "unset HISTFILE" >> /etc/profile
log_success "Final cleanup done."


for link in autoscriptx asx; do
  ln -sf /usr/bin/menu /usr/bin/$link
  chmod +x /usr/bin/$link
done


log_success "Installation complete."
log_success "Run '${green}autoscriptx${nc}' or '${green}asx${nc}' to start."
