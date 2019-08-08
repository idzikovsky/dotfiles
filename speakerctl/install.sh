#!/bin/sh

sudo cp ./speakerctl /usr/local/bin
sudo chmod +x /usr/local/bin/speakerctl
[ ! -e "/var/lib/speakerctl.token" ] && sudo /usr/local/bin/speakerctl login
sudo cp ./speakerctl.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable speakerctl
