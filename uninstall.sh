#!/bin/bash

green="\033[0;32m"
red="\033[0;31m"
yellow="\033[1;33m"
blue="\033[0;34m"
nc="\033[0m"

log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "Run as root."
    exit 1
fi

clear

echo "-----------------------------"
echo "  Uninstalling AutoScriptX  "
echo "-----------------------------"

log_info "Stopping and disabling services..."

# Stop and disable all AutoScriptX services
services=(
  dropbear
  ws-proxy.service
  nginx
  stunnel4
  sshguard
  squid
)

for service in "${services[@]}"; do
  log_info "Stopping $service..."
  systemctl disable --now "$service" > /dev/null 2>&1 || log_warning "Failed to stop $service"
done

# Stop BadVPN services
for port in 7200 7300; do
  log_info "Stopping badvpn-udpgw@$port.service..."
  systemctl disable --now badvpn-udpgw@"$port".service > /dev/null 2>&1 || log_warning "Failed to stop badvpn-udpgw@$port.service"
done

# Kill any remaining processes
pkill -f badvpn-udpgw > /dev/null 2>&1 || true
pkill -f ws-proxy > /dev/null 2>&1 || true

log_info "Removing installed files and configurations..."

# Remove main AutoScriptX directory
rm -rf /etc/AutoScriptX

# Remove SSL certificates and acme.sh
rm -rf /root/.acme.sh

# Remove stunnel configuration and certificates
rm -f /etc/stunnel/stunnel.{conf,pem} /etc/stunnel/{key.pem,cert.pem}

# Remove dropbear configuration
rm -f /etc/default/dropbear
sed -i '/AutoScriptX\/banner/d' /etc/default/dropbear 2>/dev/null

# Remove systemd service files
rm -f /etc/systemd/system/ws-proxy.service
rm -f /etc/systemd/system/badvpn-udpgw@.service

# Remove binaries
rm -f /usr/local/bin/ws-proxy /usr/bin/badvpn-udpgw /usr/local/bin/gum

# Remove nginx configurations
rm -f /etc/nginx/nginx.conf /etc/nginx/conf.d/{reverse-proxy.conf,real_ip_sources.conf}
rm -f /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf
rm -rf /home/vps/public_html

# Remove squid configuration
rm -f /etc/squid/squid.conf

# Remove cron jobs
rm -f /etc/cron.d/auto-reboot /etc/cron.d/clean-expired-accounts

# Remove scripts
for cmd in autoscriptx asx menu create-account delete-account edit-banner edit-response \
            lock-unlock renew-account change-domain manage-services system-info clean-expired-accounts; do
  rm -f /usr/bin/$cmd
done

log_info "Cleaning up system modifications..."

# Clean up /etc/shells modifications
sed -i '/\/bin\/false/d;/\/usr\/sbin\/nologin/d' /etc/shells

# Re-enable IPv6 (reverse the installer's IPv6 disable)
rm -f /etc/sysctl.d/99-disable-ipv6.conf
echo "net.ipv6.conf.all.disable_ipv6 = 0" > /etc/sysctl.d/99-enable-ipv6.conf
echo "net.ipv6.conf.default.disable_ipv6 = 0" >> /etc/sysctl.d/99-enable-ipv6.conf
sysctl --system > /dev/null 2>&1 || log_warning "Failed to reload sysctl settings"

# Clean up /etc/profile modifications (remove HISTFILE unset)
sed -i '/unset HISTFILE/d' /etc/profile

# Reset iptables rules
log_info "Resetting firewall rules..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies to ACCEPT (reverse restrictive rules)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Save the cleaned rules
netfilter-persistent save > /dev/null 2>&1
netfilter-persistent reload > /dev/null 2>&1

# Clean up iptables files
rm -f /etc/iptables.up.rules

log_info "Removing installed packages..."

# Remove packages that were specifically installed by AutoScriptX
# Note: Being conservative here - only removing packages that are primarily for AutoScriptX
packages_to_remove=(
  stunnel4
  dropbear
  squid
  sshguard
)

for package in "${packages_to_remove[@]}"; do
  log_info "Removing package: $package"
  apt purge -y "$package" > /dev/null 2>&1 || log_warning "Failed to remove $package"
done

# Clean up package dependencies
apt autoremove -y > /dev/null 2>&1
apt autoclean -y > /dev/null 2>&1

log_info "Reloading systemd daemon..."
systemctl daemon-reload > /dev/null 2>&1

log_info "Restarting remaining services..."
# Restart cron to reload without AutoScriptX jobs
service cron restart > /dev/null 2>&1 || log_warning "Failed to restart cron"

log_success "AutoScriptX uninstalled successfully."
log_info "System has been restored to its previous state."
