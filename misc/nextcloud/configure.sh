#!/bin/bash

echo "Enter hostname:"
read NC_HOSTNAME

echo "Enter new database password:"
read NC_DB_PASSWORD

sed -e "s/__NC_HOSTNAME__/$NC_HOSTNAME/" nextcloud.nginx.conf.template > nextcloud.nginx.conf
sed \
    -e "s/__NC_HOSTNAME__/$NC_HOSTNAME/" \
    -e "s/__NC_DB_PASSWORD__/$NC_DB_PASSWORD/" \
    docker-compose.yaml.template > docker-compose.yaml

sudo cp ./nextcloud.nginx.conf /etc/nginx/sites-available
sudo ln -sr /etc/nginx/sites-{available,enabled}/nextcloud.nginx.conf
sudo systemctl reload nginx

docker compose up -d

echo "Go to http://localhost:8080/ and create admin account."
echo "Press enter when you will be finished."
read dummy

echo "Configuring NextCloud server"

docker compose exec -u www-data nextcloud_app php occ config:system:set trusted_domains 0 --value "$NC_HOSTNAME"

# Setup hostname to enable direct access to Docker container on local network
docker compose exec -u www-data nextcloud_app php occ config:system:set trusted_domains 1 --value "localhost:8080"
LOCAL_IP=${LOCAL_IP:=$(ip --json r get 8.8.8.8 | jq -r '.[0].prefsrc')}
if [ -n "$LOCAL_IP" ]; then
    docker compose exec -u www-data nextcloud_app php occ config:system:set trusted_domains 2 --value "$LOCAL_IP:8080"
fi

docker compose exec -u www-data nextcloud_app php occ config:system:set overwrite.cli.url --value "http://localhost:8080"
docker compose exec -u www-data nextcloud_app php occ config:system:set overwritehost --value "$NC_HOSTNAME"
