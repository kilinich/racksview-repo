#!/bin/bash
set +e

# Stop all services
echo "Stopping appstatus..."
sudo systemctl stop appstatus.service
echo "Stopping vrecorder-front..."
sudo systemctl stop vrecorder-front.service
echo "Stopping mdetector-front..."
sudo systemctl stop mdetector-front.service
echo "Stopping gstreamer-front..."
sudo systemctl stop gstreamer-front.service

echo "Stopping vrecorder-back..."
sudo systemctl stop vrecorder-back.service
echo "Stopping mdetector-back..."
sudo systemctl stop mdetector-back.service
echo "Stopping gstreamer-back..."
sudo systemctl stop gstreamer-back.service
