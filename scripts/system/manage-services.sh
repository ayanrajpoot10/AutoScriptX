#!/bin/bash

check_status() {
  local status=$(systemctl is-active "$1" 2>/dev/null)
  [[ $status == "active" ]] && echo "$(gum style --foreground 2 'active')" || echo "$(gum style --foreground 1 'inactive')"
}

declare -A services=(
  [ssh]="SSH"
  [nginx]="Nginx"
  [dropbear]="Dropbear"
  [stunnel4]="Stunnel4"
  [cron]="Cron"
  [fail2ban]="Fail2Ban"
  [vnstat]="VnStat"
  [ws-proxy.service]="WebSocket Proxy"
  [badvpn-udpgw@7200.service]="UDPGW (7200)"
  [badvpn-udpgw@7300.service]="UDPGW (7300)"
)

gum format --theme dracula --type markdown "# ⚙️ Service Status"

for service in "${!services[@]}"; do
  status=$(check_status "$service")
  printf "  - **%-18s** : %s\n" "${services[$service]}" "$status"
done

echo

selected_services=$(printf "%s\n" "${!services[@]}" | gum choose --no-limit --height=12 --header="Select one or more services to manage")

[[ -z "$selected_services" ]] && exit 0

action=$(gum choose "start" "stop" "restart" --header="What do you want to do with selected service(s)?")

while IFS= read -r service; do
  if systemctl "$action" "$service" >/dev/null 2>&1; then
    gum style --foreground 2 "✅ ${services[$service]} $action successful."
  else
    gum style --foreground 1 "❌ Failed to $action ${services[$service]}."
  fi
done <<< "$selected_services"

gum confirm "Return to menu?" && menu
