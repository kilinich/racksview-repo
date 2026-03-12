#!/bin/bash
set -e

enable_services=(
    appstatus.service
    gstreamer-front.service
    gstreamer-back.service
    mdetector-front.service
    mdetector-back.service
    vrecorder-front.service
    vrecorder-back.service
    rvmanager.timer
)

echo "Removing legacy services..."
bash ./scripts/remove_legacy_services.sh || true

echo "Stopping services before installation..."
for service in "${enable_services[@]}"; do
    echo " - Stopping service: ${service}"
    sudo systemctl stop "${service}" || true
    sudo systemctl unmask "${service}" || true
done

APP_SRC="$(pwd)"
DEST_DIR="/opt/racksview"
SYSTEMD_DIR="/usr/lib/systemd/system"
NGINX_CONF_SRC="$APP_SRC/etc/nginx.conf"
NGINX_CONF_DEST="/usr/local/openresty/nginx/conf/nginx.conf"

echo "Creating $DEST_DIR and copying bin and etc directories..."
sudo rm -rf "$DEST_DIR"
sudo mkdir -p "$DEST_DIR"
sudo cp -r "$APP_SRC/bin" "$DEST_DIR/"
sudo cp -r "$APP_SRC/etc" "$DEST_DIR/"
sudo cp -r "$APP_SRC/var" "$DEST_DIR/"
sudo cp -r "$APP_SRC/src" "$DEST_DIR/"
sudo cp -r "$APP_SRC/scripts" "$DEST_DIR/"
sudo chmod -R +x "$DEST_DIR/bin"
sudo chmod -R +x "$DEST_DIR/scripts"

echo "Installing systemd service files..."
if [ -d "$APP_SRC/systemd" ]; then
    sudo cp -f "$APP_SRC/systemd/"*.* "$SYSTEMD_DIR/"
    sudo systemctl daemon-reload
    for service in "${enable_services[@]}"; do
        echo " - Enabling service: ${service}"
        sudo systemctl enable "${service}"
    done
fi

echo "Creating /var/log/racksview and linking to $DEST_DIR/log..."
sudo rm -rf /var/log/racksview/
sudo mkdir -p /var/log/racksview

sudo mkdir -p "$DEST_DIR/log"
if [ ! -L "$DEST_DIR/log" ]; then
    sudo rm -rf "$DEST_DIR/log"
    sudo ln -s /var/log/racksview "$DEST_DIR/log"
fi

echo "Setting up video storage directory..."
if [ -d "/media/usb" ]; then
    sudo mkdir -p /media/usb/video
    if [ ! -L "$DEST_DIR/var/video" ]; then
        sudo rm -rf "$DEST_DIR/var/video"
        sudo ln -s /media/usb/video "$DEST_DIR/var/video"
    fi
else
    sudo mkdir -p "$DEST_DIR/var/video"
fi

echo "Copying nginx.conf to $NGINX_CONF_DEST..."
sudo mkdir -p "$(dirname "$NGINX_CONF_DEST")"
sudo cp -f "$NGINX_CONF_SRC" "$NGINX_CONF_DEST"

echo "Reloading OpenResty (nginx)..."
sudo systemctl start openresty
sudo openresty -s reload

echo "Starting services..."
for service in "${enable_services[@]}"; do
    echo " - Starting service: ${service}"
    sudo systemctl start "${service}"
done

echo "Installation complete."