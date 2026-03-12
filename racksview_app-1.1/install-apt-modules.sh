#!/bin/bash

# install-apt-modules.sh
# Installs OpenResty on Debian 12 (bookworm) or Raspberry Pi 3 running latest Raspbian

set -e

echo "Updating package lists..."
sudo apt-get update

echo "Installing prerequisites..."
sudo apt-get install -y wget gnupg2 lsb-release

echo "Importing OpenResty GPG key..."
wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg

echo "Adding OpenResty repository..."
codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release`
echo "deb http://openresty.org/package/arm64/debian $codename openresty" \
    | sudo tee /etc/apt/sources.list.d/openresty.list

echo "Updating package lists (with OpenResty repo)..."
sudo apt-get update

echo "Installing OpenResty..."
sudo apt-get install -y openresty
# Add user 'nobody' to the 'video' group for querying system information
sudo usermod -aG video nobody

echo "OpenResty installation complete."

echo "Installing GStreamer and FFmpeg modules..."
sudo apt-get install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-alsa \
    gstreamer1.0-x \
    gstreamer1.0-gl \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-vaapi \
    gstreamer1.0-rtsp \
    gstreamer1.0-video \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-libcamera \
    ffmpeg \

echo "GStreamer and FFmpeg installation complete."

echo "Installing usbmount from local ./lib directory..."
sudo apt-get install -y gdebi-core
sudo gdebi -n ./lib/usbmount*.deb
echo "usbmount installation complete."

echo "Installing required Python modules system-wide..."
sudo apt-get install -y python3-pip
sudo pip3 install adafruit-circuitpython-ssd1306 pillow pyserial
echo "Python modules installation complete."
