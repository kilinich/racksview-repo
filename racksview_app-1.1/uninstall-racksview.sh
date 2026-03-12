#!/bin/bash
set +e

services=(
    appstatus.service
    gstreamer-back.service
    gstreamer-front.service
    mdetector-back.service
    mdetector-front.service
    vrecorder-back.service
    vrecorder-front.service
    rvmanager.service
    rvmanager.timer
)

for svc in "${services[@]}"; do
    sudo systemctl stop "$svc"
    sudo systemctl disable "$svc"
    sudo rm "/usr/lib/systemd/system/$svc"
done

sudo systemctl daemon-reload
sudo cp -f /usr/lib/local/openresty/nginx/conf/nginx.conf.default /usr/local/openresty/nginx/conf/nginx.conf
sudo openresty -s reload

sudo rm -rf /opt/racksview
sudo rm -rf /etc/racksview
sudo rm -rf /var/log/racksview
sudo rm -rf /tmp/racksview
