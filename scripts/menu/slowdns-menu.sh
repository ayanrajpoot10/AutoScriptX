#!/bin/bash

green="\033[0;32m"
blue="\033[0;34m"
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m"

check_slowdns_status() {
    if [ -d "/etc/slowdns" ] && [ -f "/etc/systemd/system/server-sldns.service" ]; then
        return 0
    else
        return 1
    fi
}

get_service_status() {
    local server_status="STOPPED"
    
    if systemctl is-active --quiet server-sldns 2>/dev/null; then
        server_status="RUNNING"
    fi
    
    echo "$server_status"
}

main_slowdns_menu() {
    while true; do
        clear
        
        if check_slowdns_status; then
            installation_status="Installed"
            server_status=$(get_service_status)
        else
            installation_status="Not Installed"
            server_status="N/A"
        fi
        
        if [ -f "/root/nsdomain" ]; then
            nameserver=$(cat /root/nsdomain)
        else
            nameserver="Not configured"
        fi
        
        if [ -f "/etc/AutoScriptX/slowdns-domain" ]; then
            subdomain=$(cat /etc/AutoScriptX/slowdns-domain)
        else
            subdomain="Not configured"
        fi

        gum format --theme dracula <<EOF

# 🌐 SlowDNS Server Management Center

- **Installation**    : $installation_status
- **Server Service**  : $server_status
- **Nameserver**      : $nameserver
- **Subdomain**       : $subdomain

## 🚀 SlowDNS Server Menu
EOF

        if check_slowdns_status; then
            opt=$(gum choose --limit=1 --header "  Choose Option" \
              "1. View Server Status & Configuration" \
              "2. Start SlowDNS Server" \
              "3. Stop SlowDNS Server" \
              "4. Restart SlowDNS Server" \
              "5. View Server Logs" \
              "6. Reinstall SlowDNS Server" \
              "7. Uninstall SlowDNS Server" \
              "←. Back")
        else
            opt=$(gum choose --limit=1 --header "  Choose Option" \
              "1. Install SlowDNS Server" \
              "←. Back")
        fi

        clear
        case "$opt" in
            "1. View Server Status & Configuration")
                if check_slowdns_status; then
                    slowdns-status
                else
                    echo -e "${red}SlowDNS Server is not installed.${nc}"
                    echo "Please install SlowDNS Server first."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "1. Install SlowDNS Server")
                setup-slowdns
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "2. Start SlowDNS Server")
                echo -e "${blue}[ Info    ]${nc} Starting SlowDNS server..."
                systemctl start server-sldns
                sleep 2
                if systemctl is-active --quiet server-sldns; then
                    echo -e "${green}[ Success ]${nc} SlowDNS server started successfully."
                else
                    echo -e "${red}[ Error   ]${nc} Failed to start SlowDNS server."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "3. Stop SlowDNS Server")
                echo -e "${blue}[ Info    ]${nc} Stopping SlowDNS server..."
                systemctl stop server-sldns
                sleep 2
                if ! systemctl is-active --quiet server-sldns; then
                    echo -e "${green}[ Success ]${nc} SlowDNS server stopped successfully."
                else
                    echo -e "${red}[ Error   ]${nc} Failed to stop SlowDNS server."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "4. Restart SlowDNS Server")
                echo -e "${blue}[ Info    ]${nc} Restarting SlowDNS server..."
                systemctl restart server-sldns
                sleep 2
                if systemctl is-active --quiet server-sldns; then
                    echo -e "${green}[ Success ]${nc} SlowDNS server restarted successfully."
                else
                    echo -e "${red}[ Error   ]${nc} Failed to restart SlowDNS server."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "5. View Server Logs")
                clear
                echo "=========================================="
                echo "          SlowDNS Server Logs            "
                echo "=========================================="
                echo ""
                
                echo "📋 Server Service Logs (last 30 lines):"
                echo "========================================"
                journalctl -u server-sldns --no-pager -n 30
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "6. Reinstall SlowDNS Server")
                echo -e "${yellow}[ Warning ]${nc} This will reinstall SlowDNS Server and may require reconfiguration."
                echo ""
                read -p "Are you sure you want to proceed? (y/N): " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${blue}[ Info    ]${nc} Reinstalling SlowDNS Server..."
                    setup-slowdns
                else
                    echo -e "${blue}[ Info    ]${nc} Reinstallation cancelled."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "7. Uninstall SlowDNS Server")
                echo -e "${red}[ Warning ]${nc} This will completely remove SlowDNS Server from your system."
                echo "This action cannot be undone!"
                echo ""
                read -p "Type 'CONFIRM' to proceed with uninstallation: " confirm
                
                if [ "$confirm" = "CONFIRM" ]; then
                    uninstall_slowdns
                else
                    echo -e "${blue}[ Info    ]${nc} Uninstallation cancelled."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "←. Back")
                asx
                ;;
            *)
                echo -e "${red}[ Error   ]${nc} Invalid option selected."
                sleep 2
                ;;
        esac
    done
}

main_slowdns_menu
