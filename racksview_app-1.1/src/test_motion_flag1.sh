#!/bin/bash

# Get current timestamp
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Write to motion-back.flg
echo "[$timestamp] Testing motion flag" > /opt/racksview/var/motion-back.flg

# Write to no-motion-back.flg
echo "[$timestamp] Testing no-motion flag" > /opt/racksview/var/no-motion-back.flg