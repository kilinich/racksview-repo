#!/bin/bash
set +e

SYSTEMD_DIR="/lib/systemd/system"
old_services=(
    doordetector.service
    webstreamerhigh.service
    webstreamerlow.service
    vrecorder.service
    gstreamer.service
    recwebserver.service
    gstreamer-usb.service
    gstreamer-csi.service
)

echo Stopping Legacy RacksView services...
sudo systemctl stop "${old_services[@]}" > /dev/null 2>&1

echo Disabling Legacy RacksView services...
sudo systemctl disable "${old_services[@]}" > /dev/null 2>&1

echo Removing Legacy RacksView services...
sudo rm "${SYSTEMD_DIR}/${old_services[@]}" > /dev/null 2>&1
sudo systemctl daemon-reload
