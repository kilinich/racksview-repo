#!/bin/bash

# Capture a single JPEG image from the camera and exit
v4l2-ctl --list-devices
gst-launch-1.0 v4l2src device=/dev/video1 ! 'video/x-raw,width=320,height=240' ! videoconvert ! jpegenc snapshot=true ! filesink location=test.jpg
catimg -w 240 test.jpg