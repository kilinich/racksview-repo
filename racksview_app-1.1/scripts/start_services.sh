#!/bin/bash
set +e

# Start all services
sudo systemctl start gstreamer-front.service
sudo systemctl start mdetector-front.service
sudo systemctl start vrecorder-front.service
sudo systemctl start gstreamer-back.service
sudo systemctl start mdetector-back.service
sudo systemctl start vrecorder-back.service
sudo systemctl start appstatus.service
