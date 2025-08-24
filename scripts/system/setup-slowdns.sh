#!/bin/bash

# Color definitions
green="\033[0;32m"
blue="\033[0;34m"
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m"

# Logging functions
log_info()    { echo -e "${blue}[ Info    ]${nc} $1"; }
log_success() { echo -e "${green}[ Success ]${nc} $1"; }
log_error()   { echo -e "${red}[ Error   ]${nc} $1"; }
log_warning() { echo -e "${yellow}[ Warning ]${nc} $1"; }

# Check if script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root."
        exit 1
    fi
}

# Setup SlowDNS iptables rules
setup_slowdns_iptables() {
    log_info "Setting up SlowDNS iptables rules..."
    
    # Allow UDP port 5300 for SlowDNS server
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    
    # Redirect DNS queries (port 53) to SlowDNS server (port 5300)
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # Save iptables rules
    netfilter-persistent save > /dev/null 2>&1
    netfilter-persistent reload > /dev/null 2>&1
    
    log_success "SlowDNS iptables rules applied."
}

# Get domain configuration for SlowDNS
get_slowdns_domain() {
    log_info "Configuring SlowDNS domain settings..."
    
    # Clean up any existing domain configuration
    rm -rf /root/nsdomain /etc/AutoScriptX/slowdns-domain 2>/dev/null
    
    clear
    echo "=================================="
    echo "      SlowDNS Domain Setup        "
    echo "=================================="
    echo ""
    echo "Please configure your domain for SlowDNS:"
    echo "1. Create an A record: subdomain -> VPS IP"
    echo "2. Create an NS record: slowdns-subdomain -> subdomain.domain.com"
    echo ""
    
    read -rp "Enter your main domain: " -e domain
    read -rp "Enter your subdomain: " -e sub
    
    if [[ -z "$domain" || -z "$sub" ]]; then
        log_error "Domain and subdomain cannot be empty."
        exit 1
    fi
    
    SUB_DOMAIN="${sub}.${domain}"
    NS_DOMAIN="slowdns-${SUB_DOMAIN}"
    
    # Save domain configuration
    echo "$NS_DOMAIN" > /root/nsdomain
    echo "$SUB_DOMAIN" > /etc/AutoScriptX/slowdns-domain
    
    log_success "SlowDNS domain configured: $NS_DOMAIN"
}

# Install required packages for SlowDNS
install_slowdns_packages() {
    log_info "Installing SlowDNS required packages..."
    
    apt update -y > /dev/null 2>&1
    
    # Install Python3 and DNS libraries
    apt install -y python3 python3-dnslib net-tools > /dev/null 2>&1
    apt install -y ncurses-utils dnsutils git curl > /dev/null 2>&1
    apt install -y wget screen cron iptables > /dev/null 2>&1
    apt install -y sudo gnutls-bin dos2unix debconf-utils > /dev/null 2>&1
    apt install -y openssl > /dev/null 2>&1
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to install required packages."
        exit 1
    fi
    
    # Restart cron service
    service cron reload > /dev/null 2>&1
    service cron restart > /dev/null 2>&1
    
    log_success "SlowDNS packages installed."
}

# Configure SSH ports for SlowDNS
configure_slowdns_ssh() {
    log_info "Configuring SSH ports for SlowDNS..."
    
    # Add SlowDNS SSH ports if not already present
    if ! grep -q "Port 2222" /etc/ssh/sshd_config; then
        echo "Port 2222" >> /etc/ssh/sshd_config
    fi
    
    if ! grep -q "Port 2269" /etc/ssh/sshd_config; then
        echo "Port 2269" >> /etc/ssh/sshd_config
    fi
    
    # Enable TCP forwarding for SlowDNS
    sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/g' /etc/ssh/sshd_config
    
    # Restart SSH services
    systemctl restart ssh > /dev/null 2>&1
    systemctl restart sshd > /dev/null 2>&1
    
    # Update iptables to allow new SSH ports
    iptables -I INPUT -p tcp --dport 2222 -j ACCEPT
    iptables -I INPUT -p tcp --dport 2269 -j ACCEPT
    netfilter-persistent save > /dev/null 2>&1
    
    log_success "SSH ports configured for SlowDNS."
}

# Setup SlowDNS directory and binaries
setup_slowdns_files() {
    log_info "Setting up SlowDNS server files and binaries..."
    
    # Create SlowDNS directory
    rm -rf /etc/slowdns
    mkdir -m 777 /etc/slowdns
    
    # Download SlowDNS server binary from AutoScriptX repository
    wget -q -O /etc/slowdns/dns-server "https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/main/bin/dns-server" || {
        log_error "Failed to download dns-server binary"
        exit 1
    }
    
    # Generate server private key (server.key)
    log_info "Generating server private key..."
    openssl genpkey -algorithm RSA -out /etc/slowdns/server.key -pkcs8 -v || {
        log_error "Failed to generate server private key"
        exit 1
    }
    
    # Generate server certificate (server.pem)
    log_info "Generating server certificate..."
    openssl req -new -x509 -key /etc/slowdns/server.key -out /etc/slowdns/server.pem -days 365 -subj "/C=US/ST=State/L=City/O=AutoScriptX/CN=slowdns-server" || {
        log_error "Failed to generate server certificate"
        exit 1
    }
    
    # Extract public key for client configuration
    openssl rsa -in /etc/slowdns/server.key -pubout -out /etc/slowdns/server.pub 2>/dev/null || {
        log_error "Failed to extract public key"
        exit 1
    }
    
    # Set permissions for server files
    chmod +x /etc/slowdns/dns-server
    chmod 600 /etc/slowdns/server.key
    chmod 644 /etc/slowdns/server.pem
    chmod 644 /etc/slowdns/server.pub
    
    log_success "SlowDNS server files and binaries installed."
}

# Create SlowDNS systemd services
create_slowdns_services() {
    log_info "Creating SlowDNS server systemd service..."
    
    nameserver=$(cat /root/nsdomain)
    
    # Create server service only
    cat > /etc/systemd/system/server-sldns.service << EOF
[Unit]
Description=Server SlowDNS By AutoScriptX
Documentation=https://github.com/ayanrajpoot10/AutoScriptX
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/dns-server -udp :5300 -privkey-file /etc/slowdns/server.key $nameserver 127.0.0.1:2269
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Set permissions and enable service
    chmod +x /etc/systemd/system/server-sldns.service
    
    # Stop any existing SlowDNS processes
    pkill dns-server 2>/dev/null || true
    
    # Reload systemd and start server service
    systemctl daemon-reload
    systemctl stop server-sldns 2>/dev/null || true
    
    systemctl enable server-sldns > /dev/null 2>&1
    systemctl start server-sldns > /dev/null 2>&1
    systemctl restart server-sldns > /dev/null 2>&1
    
    log_success "SlowDNS server service created and started."
}

# Create SlowDNS status check script
create_slowdns_status() {
    log_info "Creating SlowDNS status script..."
    
    cat > /usr/bin/slowdns-status << 'EOF'
#!/bin/bash

echo "=========================================="
echo "           SlowDNS Server Status          "
echo "=========================================="
echo ""

# Check if server service is running
echo "🔍 Service Status:"
echo "==================="

if systemctl is-active --quiet server-sldns; then
    echo "✅ SlowDNS Server: RUNNING"
else
    echo "❌ SlowDNS Server: STOPPED"
fi

echo ""
echo "🌐 Configuration:"
echo "=================="

if [ -f "/root/nsdomain" ]; then
    nameserver=$(cat /root/nsdomain)
    echo "📡 Nameserver: $nameserver"
else
    echo "❌ Nameserver: Not configured"
fi

if [ -f "/etc/AutoScriptX/slowdns-domain" ]; then
    subdomain=$(cat /etc/AutoScriptX/slowdns-domain)
    echo "🔗 Subdomain: $subdomain"
else
    echo "❌ Subdomain: Not configured"
fi

echo ""
echo "🔌 Network Ports:"
echo "=================="
echo "🚪 SSH Ports: 22, 2222, 2269"
echo "🌐 SlowDNS Server: 5300 (UDP)"
echo "📡 DNS Redirect: 53 → 5300 (UDP)"

echo ""
echo "📋 Public Key for Clients:"
echo "=========================="
if [ -f "/etc/slowdns/server.pub" ]; then
    echo "🔑 $(cat /etc/slowdns/server.pub)"
else
    echo "❌ Public key not found"
fi

echo ""
echo "🔐 Certificate Info:"
echo "===================="
if [ -f "/etc/slowdns/server.pem" ]; then
    echo "📜 Certificate: /etc/slowdns/server.pem"
else
    echo "❌ Certificate not found"
fi

echo ""
echo "=========================================="
EOF

    chmod +x /usr/bin/slowdns-status
    
    log_success "SlowDNS status script created."
}

# Main installation function
main() {
    clear
    echo "=========================================="
    echo "  AutoScriptX - SlowDNS Server Setup     "
    echo "=========================================="
    echo ""
    
    # Check root privileges
    check_root
    
    # Installation steps
    get_slowdns_domain
    setup_slowdns_iptables
    install_slowdns_packages
    configure_slowdns_ssh
    setup_slowdns_files
    create_slowdns_services
    create_slowdns_status
    
    # Installation complete
    clear
    echo "=========================================="
    echo "    SlowDNS Server Installation Complete! "
    echo "=========================================="
    echo ""
    log_success "SlowDNS Server has been successfully installed."
    echo ""
    echo "📋 Configuration Summary:"
    echo "========================="
    nameserver=$(cat /root/nsdomain)
    subdomain=$(cat /etc/AutoScriptX/slowdns-domain)
    echo "🌐 Nameserver: $nameserver"
    echo "🔗 Subdomain: $subdomain"
    echo "🚪 SSH Ports: 22, 2222, 2269"
    echo "📡 SlowDNS Server Port: 5300 (UDP)"
    echo ""
    echo "🔧 Management Commands:"
    echo "======================="
    echo "• Check server status: slowdns-status"
    echo "• Restart server: systemctl restart server-sldns"
    echo "• Stop server: systemctl stop server-sldns"
    echo "• Start server: systemctl start server-sldns"
    echo ""
    echo "📝 DNS Configuration Required:"
    echo "=============================="
    echo "1. Create A record: $subdomain → $(curl -s ifconfig.me)"
    echo "2. Create NS record: $nameserver → $subdomain"
    echo ""
    echo "📋 Client Configuration:"
    echo "========================"
    echo "Clients will need the following information:"
    echo "• Nameserver: $nameserver"
    echo "• Public Key: $(cat /etc/slowdns/server.pub 2>/dev/null || echo 'Not found')"
    echo "• Certificate: /etc/slowdns/server.pem"
    echo "• SSH Ports: 2222 (for clients)"
    echo ""
    echo "⚠️  Note: DNS changes may take up to 24 hours to propagate."
    echo ""
    
    # Ask if user wants to see status
    read -p "Press Enter to view SlowDNS status..."
    slowdns-status
}

# Execute main function
main "$@"
