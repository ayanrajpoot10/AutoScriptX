# xray-watcher for x-ui/3x-ui

Automatically updates Nginx locations for Xray WS accounts created via x-ui/3x-ui. Uses a systemd service with inotifywait to instantly react to database changes.

## Features
- Adds/removes Nginx `location` blocks for Xray WS accounts automatically
- Reloads Nginx only if config is valid
- Event-driven: reacts instantly to changes (no polling)

## Requirements
- Linux with systemd
- Nginx
- x-ui or 3x-ui (`/etc/x-ui/x-ui.db`)
- `sqlite3`, `jq`, `curl`, `inotify-tools`

## Install
```sh
bash <(curl -Ls https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/main/x-ui/xui-extension.sh)
```

## Usage
```sh
- Check status:  
  `systemctl status xray-watcher.service`
- View logs:  
  `journalctl -u xray-watcher.service`
- Force a run:  
  `systemctl restart xray-watcher.service`

## Uninstall
```sh
systemctl disable --now xray-watcher.service
rm -f /usr/local/bin/add-location.sh /usr/local/bin/xray-watcher.sh /etc/systemd/system/xray-watcher.service
systemctl daemon-reload
```

## Troubleshooting
- Make sure all dependencies are installed and in your PATH
- Check Nginx config with `nginx -t` if reloads fail
- View logs for errors: `journalctl -u xray-watcher.service`

## Support
Open an issue on [GitHub](https://github.com/ayanrajpoot10/AutoScriptX) for help or feature requests.
