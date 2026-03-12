#!/bin/bash
set -e

# Parameters
TARGET_BASE="/opt/racksview/var/video"    # Base directory for recorded files
KEEP_REC_DAYS=90

# Remove old recordings
find -L "${TARGET_BASE}" -type f -ctime +${KEEP_REC_DAYS} -delete

# Remove empty directories
find -L "${TARGET_BASE}" -mindepth 1 -type d -empty -delete
