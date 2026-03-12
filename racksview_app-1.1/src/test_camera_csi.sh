#!/bin/bash

# Capture a single JPEG image from the camera and exit
gst-launch-1.0 libcamerasrc ae-enable=0 analogue-gain=2.0 ! 'video/x-raw,width=320,height=240,framerate=1/1' ! videoconvert ! jpegenc snapshot=true ! filesink location=test.jpg
catimg -w 240 test.jpg