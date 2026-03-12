#!/bin/bash
# Script to configure config.txt and timesyncd.conf

# Files to modify
CONFIG_FILE="/boot/firmware/config.txt"
TIMESYNCD_CONF="/etc/systemd/timesyncd.conf"

echo "Checking $CONFIG_FILE for required dtoverlay lines..."

# Check for dtoverlay=disable-wifi
if ! grep -q "^dtoverlay=disable-wifi" "$CONFIG_FILE"; then
    echo "dtoverlay=disable-wifi" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "Added line: dtoverlay=disable-wifi"
else
    echo "Line dtoverlay=disable-wifi already exists"
fi

# Check for dtoverlay=disable-bt
if ! grep -q "^dtoverlay=disable-bt" "$CONFIG_FILE"; then
    echo "dtoverlay=disable-bt" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "Added line: dtoverlay=disable-bt"
else
    echo "Line dtoverlay=disable-bt already exists"
fi

echo "Checking $TIMESYNCD_CONF for NTP parameter..."
sudo timedatectl set-timezone UTC

# Retrieve the default gateway IP address
default_gw=$(ip route | awk '/^default/ {print $3; exit}')
if [ -z "$default_gw" ]; then
    echo "Failed to determine the default gateway. Please check your network settings." >&2
    exit 1
fi

# Check if there is an active (non-commented) line starting with NTP=
current_ntp=$(grep "^[[:space:]]*NTP=" "$TIMESYNCD_CONF" | awk -F= '{print $2}' | tr -d ' ')
if [ -z "$current_ntp" ]; then
    # Append the NTP parameter at the end of the file
    echo "NTP=$default_gw" | sudo tee -a "$TIMESYNCD_CONF" > /dev/null
    echo "Added line: NTP=$default_gw"
elif [ "$current_ntp" != "$default_gw" ]; then
    # Update the NTP parameter to the default gateway
    sudo sed -i "s|^[[:space:]]*NTP=.*|NTP=$default_gw|" "$TIMESYNCD_CONF"
    echo "Updated NTP parameter to: NTP=$default_gw"
else
    echo "NTP parameter is already set to $default_gw in $TIMESYNCD_CONF"
fi

echo "Adding cron job for weekly reboot..."
# Add a cron job to reboot the system weekly
(echo "0 3 * * 1 sudo reboot") | sudo crontab -

echo "Configuration complete."
