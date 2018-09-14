#!/bin/bash

IP_REGEX="[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"

LOCAL_IP=$(ip r get 8.8.8.8 | grep -o "src $IP_REGEX" | grep -o "$IP_REGEX")
docker-compose exec --user www-data nextcloud_app php occ config:system:set trusted_domains 1 --value="$LOCAL_IP"

GLOBAL_IP=$(curl --fail https://ifconfig.co/)
if [ "$?" = "0" ]; then
    docker-compose exec --user www-data nextcloud_app php occ config:system:set trusted_domains 1 --value="$GLOBAL_IP"
fi

GLOBAL_HOSTNAME=$(curl https://ifconfig.co/hostname)
if [ "$?" = "0" ]; then
    docker-compose exec --user www-data nextcloud_app php occ config:system:set trusted_domains 1 --value="$GLOBAL_HOSTNAME"
fi
