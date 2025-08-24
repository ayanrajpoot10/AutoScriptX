#!/bin/bash

# SlowDNS Server Status Check for AutoScriptX

# Color definitions
green="\033[0;32m"
red="\033[0;31m"
yellow="\033[1;33m"
blue="\033[0;34m"
nc="\033[0m"

echo "=========================================="
echo "           SlowDNS Server Status          "
echo "=========================================="
echo ""

# Check if SlowDNS server is installed
if [ ! -d "/etc/slowdns" ] || [ ! -f "/etc/systemd/system/server-sldns.service" ]; then
    echo -e "${red}❌ SlowDNS Server is not installed on this system.${nc}"
    echo ""
    echo "To install SlowDNS Server, run: setup-slowdns"
    exit 1
fi

# Check server service status
echo "🔍 Service Status:"
echo "==================="

if systemctl is-active --quiet server-sldns; then
    echo -e "✅ SlowDNS Server: ${green}RUNNING${nc}"
else
    echo -e "❌ SlowDNS Server: ${red}STOPPED${nc}"
fi

echo ""
echo "🌐 Configuration:"
echo "=================="

if [ -f "/root/nsdomain" ]; then
    nameserver=$(cat /root/nsdomain)
    echo -e "📡 Nameserver: ${green}$nameserver${nc}"
else
    echo -e "❌ Nameserver: ${red}Not configured${nc}"
fi

if [ -f "/etc/AutoScriptX/slowdns-domain" ]; then
    subdomain=$(cat /etc/AutoScriptX/slowdns-domain)
    echo -e "🔗 Subdomain: ${green}$subdomain${nc}"
else
    echo -e "❌ Subdomain: ${red}Not configured${nc}"
fi

echo ""
echo "🔌 Network Ports:"
echo "=================="
echo "🚪 SSH Ports: 22, 2222, 2269"
echo "🌐 SlowDNS Server: 5300 (UDP)"
echo "📡 DNS Redirect: 53 → 5300 (UDP)"

echo ""
echo "📋 Server Files:"
echo "=================="
if [ -f "/etc/slowdns/dns-server" ]; then
    echo -e "✅ DNS Server Binary: ${green}Present${nc}"
else
    echo -e "❌ DNS Server Binary: ${red}Missing${nc}"
fi

if [ -f "/etc/slowdns/server.key" ]; then
    echo -e "✅ Private Key: ${green}Present${nc}"
else
    echo -e "❌ Private Key: ${red}Missing${nc}"
fi

if [ -f "/etc/slowdns/server.pem" ]; then
    echo -e "✅ Certificate: ${green}Present${nc}"
else
    echo -e "❌ Certificate: ${red}Missing${nc}"
fi

if [ -f "/etc/slowdns/server.pub" ]; then
    echo -e "✅ Public Key: ${green}Present${nc}"
else
    echo -e "❌ Public Key: ${red}Missing${nc}"
fi

echo ""
echo "📋 Public Key for Client Configuration:"
echo "========================================"
if [ -f "/etc/slowdns/server.pub" ]; then
    echo -e "🔑 ${blue}$(cat /etc/slowdns/server.pub)${nc}"
else
    echo -e "❌ ${red}Public key not found${nc}"
fi

echo ""
echo "📝 Required DNS Configuration:"
echo "==============================="
if [ -f "/etc/AutoScriptX/slowdns-domain" ] && [ -f "/root/nsdomain" ]; then
    subdomain=$(cat /etc/AutoScriptX/slowdns-domain)
    nameserver=$(cat /root/nsdomain)
    public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to get IP")
    echo -e "${yellow}A record:${nc}  $subdomain → $public_ip"
    echo -e "${yellow}NS record:${nc} $nameserver → $subdomain"
else
    echo -e "${red}❌ Configuration incomplete${nc}"
fi

echo ""
echo "🔧 Management Commands:"
echo "======================="
echo "• Status check: slowdns-status"
echo "• Restart server: systemctl restart server-sldns"
echo "• Stop server: systemctl stop server-sldns"
echo "• Start server: systemctl start server-sldns"
echo "• View logs: journalctl -u server-sldns -f"

echo ""
echo "=========================================="
