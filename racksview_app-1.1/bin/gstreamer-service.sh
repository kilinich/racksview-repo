#!/bin/bash
set +e

# Check and parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Ensure required parameter is set
if [[ -z "${PROFILE}" ]]; then
    echo "Usage: $0 --profile <front|back>"
    exit 1
fi

# Assign variables based on profile
case "$PROFILE" in
    front)
        CAM_DEV="CSI"
        PORT_HIGH=8013
        PORT_LOW=8012
        OVLABEL="door1"
        ;;
    back)
        CAM_DEV="/dev/video0"
        PORT_HIGH=9013
        PORT_LOW=9012
        OVLABEL="door2"
        ;;
    *)
        echo "Invalid profile: $PROFILE. Use 'front' or 'back'."
        exit 1
        ;;
esac

export GST_DEBUG=1
# Start the gstreamer pipeline

# This pipeline captures video from the camera, adds a text overlay with the hostname and current time,
# scales the video to two different resolutions, encodes the video as jpeg, and sends the video over TCP to two different ports.

if [[ "$CAM_DEV" == "CSI" ]]; then
    # Start the gstreamer pipeline for CSI (built-in) camera
    gst-launch-1.0 -q -e \
    libcamerasrc name=src ! queue leaky=2 ! video/x-raw,framerate=1/1 ! tee name=t \
        t. ! queue leaky=2 ! videoscale ! video/x-raw,width=1296,height=972 !\
            textoverlay text="$HOSTNAME-$OVLABEL" valignment=top halignment=left font-desc="Sans, 8" xpos=10 ypos=10 ! \
            clockoverlay time-format="%d-%m-%Y %H:%M.%S" valignment=bottom halignment=left font-desc="Sans, 8" xpos=10 ypos=-10 ! \
            v4l2jpegenc ! multipartmux ! \
            tcpserversink host=127.0.0.1 port=$PORT_HIGH recover-policy=3 sync=false \
        t. ! queue leaky=2 ! videoscale ! video/x-raw,width=320,height=240 ! \
            textoverlay text="$HOSTNAME-$OVLABEL" valignment=top halignment=left font-desc="Sans, 20" xpos=2 ypos=2 ! \
            clockoverlay time-format="%H:%M.%S" valignment=bottom halignment=left font-desc="Sans, 20" xpos=2 ypos=-2 ! \
            jpegenc quality=60 ! multipartmux ! \
            tcpserversink host=127.0.0.1 port=$PORT_LOW recover-policy=3 sync=false
else
    # Start the gstreamer pipeline for USB camera
    gst-launch-1.0 -q -e \
    v4l2src device=$CAM_DEV ! queue leaky=2 ! image/jpeg,width=1280,height=800,framerate=10/1 ! videorate ! image/jpeg,framerate=1/1 ! v4l2jpegdec ! video/x-raw ! tee name=t \
        t. ! queue leaky=2 ! \
            textoverlay text="$HOSTNAME-$OVLABEL" valignment=top halignment=left font-desc="Sans, 8" xpos=10 ypos=10 ! \
            clockoverlay time-format="%d-%m-%Y %H:%M.%S" valignment=bottom halignment=left font-desc="Sans, 8" xpos=10 ypos=-10 ! \
            v4l2jpegenc ! multipartmux ! \
            tcpserversink host=127.0.0.1 port=$PORT_HIGH recover-policy=3 sync=false \
        t. ! queue leaky=2 ! videoscale ! video/x-raw,width=320,height=240 ! \
            textoverlay text="$HOSTNAME-$OVLABEL" valignment=top halignment=left font-desc="Sans, 20" xpos=2 ypos=2 ! \
            clockoverlay time-format="%H:%M.%S" valignment=bottom halignment=left font-desc="Sans, 20" xpos=2 ypos=-2 ! \
            jpegenc quality=60 ! multipartmux ! \
            tcpserversink host=127.0.0.1 port=$PORT_LOW recover-policy=3 sync=false
fi