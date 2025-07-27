#!/bin/bash

LOCATION_DIR="/etc/nginx/locations"
mkdir -p "$LOCATION_DIR"

LOCATION_PATH="$1"
PORT="$2"

FILENAME=$(echo "$LOCATION_PATH" | sed 's|^/||').conf
FILEPATH="$LOCATION_DIR/$FILENAME"

cat > "$FILEPATH" <<EOF
location $LOCATION_PATH {
    proxy_redirect off;
    proxy_pass http://127.0.0.1:$PORT;
    proxy_http_version 1.1;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$http_host;
}
EOF

nginx -t && systemctl reload nginx && echo "Nginx reloaded successfully." || {
    echo "Error reloading Nginx."
    rm "$FILEPATH"
}
