#!/bin/bash

# Get current timestamp
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Write to motion-front.flg
echo "[$timestamp] Testing motion flag" > /opt/racksview/var/motion-front.flg

# Write to no-motion-front.flg
echo "[$timestamp] Testing no-motion flag" > /opt/racksview/var/no-motion-front.flg