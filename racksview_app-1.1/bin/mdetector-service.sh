#!/bin/bash

# Function to show usage
usage() {
    echo "Usage: $0 --profile <front|back>"
    exit 1
}

# Parse arguments
if [[ "$1" != "--profile" ]] || [[ -z "$2" ]]; then
    usage
fi

PROFILE="$2"

case "$PROFILE" in
    front)
        PORT="/dev/serial0"
        BAUD="115200"
        FLAG="/opt/racksview/var/motion-front.flg"
        UNFLAG="/opt/racksview/var/no-motion-front.flg"
        DUMP="/dev/shm/mdetector-front.txt"
        ;;
    back)
        PORT="/dev/ttyUSB0"
        BAUD="115200"
        FLAG="/opt/racksview/var/motion-back.flg"
        UNFLAG="/opt/racksview/var/no-motion-back.flg"
        DUMP="/dev/shm/mdetector-back.txt"
        ;;
    *)
        echo "Invalid profile: $PROFILE"
        usage
        ;;
esac

# Export or use the variables as needed
echo "Selected profile: $PROFILE"
echo "PORT=$PORT"
echo "BAUD=$BAUD"
echo "FLAG=$FLAG"
echo "UNFLAG=$UNFLAG"
echo "DUMP=$DUMP"

# /opt/racksview/bin/motion_detector.bin --port "$PORT" --baud "$BAUD" --flag "$FLAG" --unflag "$UNFLAG" > /dev/null
/usr/bin/python3 /opt/racksview/src/motion_detector.py --port "$PORT" --baud "$BAUD" --flag "$FLAG" --unflag "$UNFLAG" --dump "$DUMP"