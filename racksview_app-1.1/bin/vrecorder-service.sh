#!/bin/bash
set +e

# Parse --profile argument
if [[ "$1" == "--profile" && -n "$2" ]]; then
    PROFILE="$2"
    shift 2
else
    echo "Usage: $0 --profile <front|back>"
    exit 1
fi

# Apply profile settings
case "$PROFILE" in
    front)
        SOURCE_PORT=8013
        FILE_NAME="event-door1"
        START_FLAG="/opt/racksview/var/motion-front.flg"
        STOP_FLAG="/opt/racksview/var/no-motion-front.flg"
        ;;
    back)
        SOURCE_PORT=9013
        FILE_NAME="event-door2"
        START_FLAG="/opt/racksview/var/motion-back.flg"
        STOP_FLAG="/opt/racksview/var/no-motion-back.flg"
        ;;
    *)
        echo "Unknown profile: $PROFILE"
        exit 1
        ;;
esac

# Configuration
RUN_ON_START_REC="/opt/racksview/notify/on_start_recording.sh"
RUN_ON_STOP_REC="/opt/racksview/notify/on_stop_recording.sh"
TARGET_BASE="/opt/racksview/var/video"
TEMP_NAME="_recording-in-progress"
SEGMENT_DURATION=300
BITRATE=100

# Log parameters and config to stdout
echo "Starting vrecorder with the following parameters:"
echo "  SOURCE_PORT: ${SOURCE_PORT}"
echo "  FILE_NAME: ${FILE_NAME}"
echo "  START_FLAG: ${START_FLAG}"
echo "  STOP_FLAG: ${STOP_FLAG}"
echo "Configuration:"
echo "  RUN_ON_START_REC: ${RUN_ON_START_REC}"
echo "  RUN_ON_STOP_REC: ${RUN_ON_STOP_REC}"
echo "  TARGET_BASE: ${TARGET_BASE}"
echo "  TEMP_NAME: ${TEMP_NAME}"
echo "  SEGMENT_DURATION: ${SEGMENT_DURATION}"
echo "  BITRATE: ${BITRATE}"

# Initialize flags
rm -f "${START_FLAG}"
rm -f "${STOP_FLAG}"

echo "Setting up video storage directory..."
if [ -d "/media/usb" ]; then
    sudo mkdir -p /media/usb/video
    if [ ! -L "$TARGET_BASE" ]; then
        sudo rm -rf "$TARGET_BASE"
        sudo ln -s /media/usb/video "$TARGET_BASE"
    fi
else
    sudo mkdir -p "$TARGET_BASE"
fi

while true
do    
    # Wait for the start flag to be created
    if [ -f "${START_FLAG}" ]; then
        # Run the start recording script
        "${RUN_ON_START_REC}" ${FILE_NAME}

        # Loop until the stop flag is created
        while true
        do
            # Get current date/time components
            YEAR=$(date +%Y)
            MONTH=$(date +%m)
            DAY=$(date +%d)
            HOUR=$(date +%H)
            MINUTE=$(date +%M)

            # Create target directory if it doesn't exist
            TARGET_DIR="${TARGET_BASE}/${YEAR}-${MONTH}-${DAY}"
            mkdir -p "${TARGET_DIR}" 2>/dev/null

            # Build output file name with hours, minutes, and seconds
            OUTPUT_FILE="${HOUR}-${MINUTE}_${FILE_NAME}"
            FULL_PATH="${TARGET_DIR}/${OUTPUT_FILE}"
            
            #Check free space, delete old files if needed
            /opt/racksview/scripts/check_free_space.sh ${TARGET_BASE}

            # Run ffmpeg to record a segment, overwriting any existing file (-y)
            ffmpeg -y -loglevel warning -r 1 -i tcp://127.0.0.1:${SOURCE_PORT} \
            -t ${SEGMENT_DURATION} \
            -c:v libx264 -preset veryfast -threads 1 -b:v ${BITRATE}k \
            "${FULL_PATH}${TEMP_NAME}.mp4"

            mv -f "${FULL_PATH}${TEMP_NAME}.mp4" "${FULL_PATH}.mp4"

            # Check if the stop flag exists or start flag removed
            if [ -f "${STOP_FLAG}" ] || [ ! -f "${START_FLAG}" ]; then
                rm -f "${STOP_FLAG}"
                rm -f "${START_FLAG}"            
                # Run the stop recording script
                "${RUN_ON_STOP_REC}" ${FILE_NAME}
                break
            fi                   
        done
    else
        sleep 1
    fi
done
