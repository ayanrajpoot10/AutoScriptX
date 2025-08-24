#!/bin/bash

# Color definitions
green="\033[0;32m"
blue="\033[0;34m"
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m"

# Configuration
BASE_URL="https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/master"
export DEBIAN_FRONTEND=noninteractive

# Global variables
localip=""
public_ip=""
hostname=""
domain=""

# Logging functions
log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }

# Check if script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Run as root."
        exit 1
    fi
}

# Setup hostname and hosts file
setup_hosts() {
    log_info "Setting up hostname and hosts file..."
    localip=$(hostname -I | cut -d ' ' -f1)
    public_ip=$(curl -s ifconfig.me)
    hostname=$(hostname)
    domain_from_etc=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')
    [ "$hostname" != "$domain_from_etc" ] && echo "$localip $hostname" >> /etc/hosts
    log_success "Hostname and hosts file configured."
}

# Setup domain configuration
setup_domain() {
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
}


# Update system packages
update_system() {
    log_info "Updating system..."
    apt update -y > /dev/null 2>&1 && apt dist-upgrade -y > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then 
        log_error "System update failed."
        exit 1
    fi
    apt-get purge -y ufw firewalld exim4 samba* apache2* bind9* sendmail* unscd > /dev/null 2>&1 || log_warning "Some packages could not be purged (may not be installed)."
    apt autoremove -y > /dev/null 2>&1 && apt autoclean -y > /dev/null 2>&1
    log_success "System updated."
}

# Install required packages
install_packages() {
    log_info "Installing packages..."
    apt install -y \
      netfilter-persistent iptables-persistent screen curl jq bzip2 gzip vnstat coreutils rsyslog \
      zip unzip net-tools nano lsof shc gnupg dos2unix dirmngr bc \
      stunnel4 nginx dropbear socat xz-utils sshguard squid > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then 
        log_error "Failed to install one or more packages."
        exit 1
    fi
    log_success "Packages installed."
}

# Setup Squid proxy
configure_squid() {
    log_info "Setting up Squid proxy..."
    wget -qO /etc/squid/squid.conf "$BASE_URL/config/squid.conf" || log_error "Failed to download squid.conf."
    sed -i "s/IP/$public_ip/g" /etc/squid/squid.conf
    chmod 644 /etc/squid/squid.conf
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1 || log_error "Failed to restart Squid."
    log_success "Squid proxy set up."
}

# Install gum tool
install_gum() {
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
}

# Disable IPv6
disable_ipv6() {
    log_info "Disabling IPv6..."
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
    sysctl --system > /dev/null 2>&1 || log_warning "Failed to reload sysctl settings."
    log_success "IPv6 disabled."
}

# Configure Dropbear SSH
configure_dropbear() {
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
}


# Setup WebSocket service
setup_websocket_service() {
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
}

# Setup SSL certificate
setup_ssl_cert() {
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
}

# Configure Nginx
configure_nginx() {
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
}

# Setup BadVPN
setup_badvpn() {
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
}


# Configure Stunnel
configure_stunnel() {
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
}

# Configure SSHGuard
configure_sshguard() {
    log_info "Configuring SSHGuard..."
    systemctl enable sshguard > /dev/null 2>&1
    systemctl restart sshguard > /dev/null 2>&1 || log_warning "Failed to restart sshguard."
    log_success "SSHGuard configured."
}

# Apply firewall rules
apply_firewall_rules() {
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

    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT

    if grep -q "--dport 22" /etc/iptables/rules.v4; then
      sed -i "/--dport 22 -j ACCEPT/a \\n-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT\n-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT\n-A INPUT -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT" /etc/iptables/rules.v4
    else
      echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT" >> /etc/iptables/rules.v4
      echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT" >> /etc/iptables/rules.v4
      echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT" >> /etc/iptables/rules.v4
      echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT" >> /etc/iptables/rules.v4
    fi

    netfilter-persistent save > /dev/null 2>&1 || log_warning "Failed to save iptables rules."
}


# Install scripts
install_scripts() {
    log_info "Installing scripts..."
    declare -A script_dirs=(
      [menu]="menu.sh slowdns-menu.sh xui-menu.sh"
      [ssh]="create-account.sh delete-account.sh edit-banner.sh edit-response.sh lock-unlock.sh renew-account.sh"
      [system]="change-domain.sh manage-services.sh system-info.sh clean-expired-accounts.sh setup-slowdns.sh slowdns-status.sh"
    )
    for dir in "${!script_dirs[@]}"; do
      for s in ${script_dirs[$dir]}; do
        base="${s%.sh}"
        wget -qO "/usr/bin/$base" "$BASE_URL/scripts/$dir/$s" > /dev/null 2>&1 || log_warning "Failed to download $s."
        chmod +x "/usr/bin/$base"
      done
    done
    
    # Install uninstall script to AutoScriptX directory
    wget -qO /etc/AutoScriptX/uninstall.sh "$BASE_URL/uninstall.sh" > /dev/null 2>&1 || log_warning "Failed to download uninstall.sh."
    chmod +x /etc/AutoScriptX/uninstall.sh
    
    log_success "Scripts installed."
}

# Setup cron jobs
setup_cron_jobs() {
    log_info "Setting up cron jobs..."
    wget -qO /etc/cron.d/auto-reboot "$BASE_URL/service/cron/auto-reboot" || log_error "Failed to download auto-reboot."
    wget -qO /etc/cron.d/clean-expired-accounts "$BASE_URL/service/cron/clean-expired-accounts" || log_error "Failed to download clean-expired-accounts."
    service cron restart > /dev/null 2>&1
    log_success "Cron jobs set up."
}

# Final cleanup and setup
final_cleanup() {
    log_info "Final cleanup..."
    chown -R www-data:www-data /home/vps/public_html
    history -c && echo "unset HISTFILE" >> /etc/profile
    
    # Create symbolic links
    for link in autoscriptx asx; do
      ln -sf /usr/bin/menu /usr/bin/$link
      chmod +x /usr/bin/$link
    done
    
    log_success "Final cleanup done."
}

# Main function that orchestrates the installation
main() {
    # Initial setup and validation
    check_root
    setup_hosts
    setup_domain
    
    # System preparation
    update_system
    install_packages
    
    # Service configurations
    configure_squid
    install_gum
    disable_ipv6
    configure_dropbear
    setup_websocket_service
    setup_ssl_cert
    configure_nginx
    setup_badvpn
    configure_stunnel
    configure_sshguard
    
    # Security and finalization
    apply_firewall_rules
    install_scripts
    setup_cron_jobs
    final_cleanup
    
    # Installation complete
    log_success "Installation complete."
    log_success "Run '${green}autoscriptx${nc}' or '${green}asx${nc}' to start."
}

# Execute main function
main "$@"
