#!/bin/bash

green="\033[0;32m"
blue="\033[0;34m"
red="\033[0;31m"
yellow="\033[1;33m"
nc="\033[0m"

check_xui_status() {
    if command -v x-ui >/dev/null 2>&1 || systemctl list-units --type=service | grep -qE 'x-ui'; then
        return 0
    else
        return 1
    fi
}

get_service_status() {
    local xui_status="STOPPED"
    
    if systemctl is-active --quiet x-ui 2>/dev/null; then
        xui_status="RUNNING"
    fi
    
    echo "$xui_status"
}

get_xui_info() {
    local port="Not configured"
    local path=""
    
    if command -v x-ui >/dev/null 2>&1; then
        if [ -f "/etc/x-ui/x-ui.db" ]; then
            port=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webPort';" 2>/dev/null || echo "54321")
            path=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webBasePath';" 2>/dev/null || echo "")
        else
            port="54321 (default)"
            path=""
        fi
    fi
    
    echo "$port|$path"
}

main_xui_menu() {
    while true; do
        clear
        
        if check_xui_status; then
            installation_status="Installed"
            service_status=$(get_service_status)
            info=$(get_xui_info)
            port=$(echo "$info" | cut -d'|' -f1)
            path=$(echo "$info" | cut -d'|' -f2)
        else
            installation_status="Not Installed"
            service_status="N/A"
            port="N/A"
            path="N/A"
        fi
        
        if command -v curl >/dev/null 2>&1; then
            public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")
        else
            public_ip="Unknown"
        fi

        if [ "$port" != "N/A" ] && [ "$public_ip" != "Unknown" ]; then
            if [ -n "$path" ] && [ "$path" != "" ]; then
                access_url="http://$public_ip:$port$path"
            else
                access_url="http://$public_ip:$port"
            fi
        else
            access_url="N/A"
        fi

        if [ -n "$path" ] && [ "$path" != "" ]; then
            path_display="$path"
        else
            path_display="/ (root)"
        fi

        gum format --theme dracula <<EOF

# 🎛️ X-UI Management Center

- **Installation**    : $installation_status
- **Service Status**  : $service_status
- **Web Port**        : $port
- **Web Path**        : $path_display
- **Access URL**      : $access_url

# 🚀 X-UI Menu
EOF

        if check_xui_status; then
            opt=$(gum choose --limit=1 --header "  Choose Option" \
              "1. Open X-UI Admin Panel" \
              "2. Start X-UI Service" \
              "3. Stop X-UI Service" \
              "4. Restart X-UI Service" \
              "5. View Service Status" \
              "6. X-UI Settings" \
              "7. Enable Auto-start" \
              "8. Disable Auto-start" \
              "9. View Service Logs" \
              "←. Back" \
              "10. View Ban Logs" \
              "11. Update X-UI" \
              "12. Legacy Version" \
              "13. Reinstall X-UI" \
              "14. Uninstall X-UI" \
              "←.  Back")
        else
            opt=$(gum choose --limit=1 --header "  Choose Option" \
              "1. Install X-UI" \
              "←. Back")
        fi

        clear
        case "$opt" in
            "1. Open X-UI Admin Panel")
                if check_xui_status; then
                    x-ui
                else
                    echo -e "${red}X-UI is not installed.${nc}"
                    echo "Please install X-UI first."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "1. Install X-UI")
                echo -e "${blue}[ Info    ]${nc} Installing X-UI using xui-extension.sh..."
                bash <(curl -Ls https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/main/x-ui/xui-extension.sh)
                echo -e "${green}[ Success ]${nc} X-UI installation completed."
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "2. Start X-UI Service")
                echo -e "${blue}[ Info    ]${nc} Starting X-UI service..."
                systemctl start x-ui
                sleep 2
                if systemctl is-active --quiet x-ui; then
                    echo -e "${green}[ Success ]${nc} X-UI service started successfully."
                else
                    echo -e "${red}[ Error   ]${nc} Failed to start X-UI service."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "3. Stop X-UI Service")
                echo -e "${blue}[ Info    ]${nc} Stopping X-UI service..."
                systemctl stop x-ui
                sleep 2
                if ! systemctl is-active --quiet x-ui; then
                    echo -e "${green}[ Success ]${nc} X-UI service stopped successfully."
                else
                    echo -e "${red}[ Error   ]${nc} Failed to stop X-UI service."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "4. Restart X-UI Service")
                echo -e "${blue}[ Info    ]${nc} Restarting X-UI service..."
                systemctl restart x-ui
                sleep 2
                if systemctl is-active --quiet x-ui; then
                    echo -e "${green}[ Success ]${nc} X-UI service restarted successfully."
                else
                    echo -e "${red}[ Error   ]${nc} Failed to restart X-UI service."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "5. View Service Status")
                clear
                echo "=========================================="
                echo "            X-UI Service Status           "
                echo "=========================================="
                systemctl status x-ui --no-pager
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "6. X-UI Settings")
                x-ui settings
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "7. Enable Auto-start")
                echo -e "${blue}[ Info    ]${nc} Enabling X-UI auto-start..."
                systemctl enable x-ui
                echo -e "${green}[ Success ]${nc} X-UI auto-start enabled."
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "8. Disable Auto-start")
                echo -e "${blue}[ Info    ]${nc} Disabling X-UI auto-start..."
                systemctl disable x-ui
                echo -e "${green}[ Success ]${nc} X-UI auto-start disabled."
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "9. View Service Logs")
                clear
                echo "=========================================="
                echo "            X-UI Service Logs            "
                echo "=========================================="
                echo ""
                echo "📋 X-UI Service Logs (last 30 lines):"
                echo "======================================"
                journalctl -u x-ui --no-pager -n 30
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "10. View Ban Logs")
                clear
                echo "=========================================="
                echo "            X-UI Ban Logs                "
                echo "=========================================="
                if [ -f /var/log/fail2ban.log ]; then
                    echo "📋 Fail2ban Ban Logs:"
                    echo "==================="
                    cat /var/log/fail2ban.log | grep BAN | tail -20
                else
                    echo -e "${yellow}[ Warning ]${nc} Fail2ban log not found."
                    echo "Fail2ban may not be installed or configured."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "11. Update X-UI")
                echo -e "${blue}[ Info    ]${nc} Updating X-UI..."
                x-ui update
                echo -e "${green}[ Success ]${nc} X-UI update completed."
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "12. Legacy Version")
                echo -e "${blue}[ Info    ]${nc} Switching to legacy version..."
                x-ui legacy
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "13. Reinstall X-UI")
                echo -e "${yellow}[ Warning ]${nc} This will reinstall X-UI and may require reconfiguration."
                echo ""
                read -p "Are you sure you want to proceed? (y/N): " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${blue}[ Info    ]${nc} Reinstalling X-UI..."
                    bash <(curl -Ls https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/main/x-ui/xui-extension.sh)
                    echo -e "${green}[ Success ]${nc} X-UI reinstallation completed."
                else
                    echo -e "${blue}[ Info    ]${nc} Reinstallation cancelled."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "14. Uninstall X-UI")
                echo -e "${red}[ Warning ]${nc} This will completely remove X-UI from your system."
                echo "This action cannot be undone!"
                echo ""
                read -p "Type 'CONFIRM' to proceed with uninstallation: " confirm
                
                if [ "$confirm" = "CONFIRM" ]; then
                    echo -e "${blue}[ Info    ]${nc} Uninstalling X-UI..."
                    x-ui uninstall
                    echo -e "${green}[ Success ]${nc} X-UI has been uninstalled."
                else
                    echo -e "${blue}[ Info    ]${nc} Uninstallation cancelled."
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "←. Back" | "←.  Back")
                asx
                ;;
            *)
                echo -e "${red}[ Error   ]${nc} Invalid option selected."
                sleep 2
                ;;
        esac
    done
}

main_xui_menu
