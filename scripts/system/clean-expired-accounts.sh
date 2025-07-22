#!/bin/bash


current_time=$(date +%s)

while IFS=: read -r username _ _ _ _ _ _ expire_days _; do
    [[ -z $expire_days || $expire_days -eq 0 ]] && continue
    expiration_time=$((expire_days * 86400))
    if (( expiration_time < current_time )); then
        userdel --force "$username"
    fi
done < /etc/shadow
