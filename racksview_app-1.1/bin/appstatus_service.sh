#!/bin/bash

trap "exit" INT TERM

get_motion_status() {
    local flag=$1
    local unflag=$2
    local dump=$3
    local result=""

    if [ -r "$dump" ]; then
        result="monitoring $(cat "$dump")"
    else
        result="no monitoring data"
    fi

    if [ -r "$flag" ]; then
        result="${result}\n$(cat "$flag")"
    fi

    if [ -r "$unflag" ]; then
        result="${result}\n$(cat "$unflag")"
    fi

    echo -e "$result"
}

get_service_status() {
    local name=$1
    local status=$(systemctl is-active "$name" 2>/dev/null)
    local uptime=$(systemctl show -p ActiveEnterTimestamp "$name" 2>/dev/null | grep ActiveEnterTimestamp | cut -d= -f2)
    [ -z "$uptime" ] && uptime="N/A"
    [ -z "$status" ] && status="N/A"
    echo "$status, $uptime"
}

get_hostname() {
    uname -n | awk '{$1=$1;print}'
}

get_os_version() {
    cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d '"' -f2 | awk '{$1=$1;print}'
}

get_kernel_version() {
    uname -r | awk '{$1=$1;print}'
}

get_uptime() {
    uptime -p | awk '{$1=$1;print}'
}

get_cpu_temp() {
    local temp=$(vcgencmd measure_temp 2>/dev/null | awk '{$1=$1;print}')
    local throttle=$(vcgencmd get_throttled 2>/dev/null | awk '{$1=$1;print}')
    local res="$temp $throttle"
    echo "$res" | awk '{$1=$1;print}'
}

get_radio_status() {
    local output=$(rfkill list all 2>/dev/null)
    if [ -z "$output" ]; then
        echo "disabled"
    else
        echo "$output" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
    fi
}

get_ram_usage() {
    local memtotal=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local memavail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    
    if [ -n "$memtotal" ] && [ -n "$memavail" ]; then
        local used=$((memtotal - memavail))
        local used_mb=$(awk "BEGIN {printf \"%.1f\", $used/1024}")
        local total_mb=$(awk "BEGIN {printf \"%.1f\", $memtotal/1024}")
        echo "$used_mb MB / $total_mb MB"
    else
        echo "N/A"
    fi
}

get_disk_usage() {
    local folder=$1
    local line=$(df -h "$folder" 2>/dev/null | tail -n 1)
    local total=$(echo "$line" | awk '{print $2}')
    local used=$(echo "$line" | awk '{print $3}')
    if [ -n "$total" ] && [ -n "$used" ]; then
        echo "$used GB / $total GB"
    else
        echo "N/A"
    fi
}

get_ip_address() {
    hostname -I 2>/dev/null | awk '{$1=$1;print}'
}

get_CPU_usage() {
    cat /proc/loadavg 2>/dev/null | awk '{$1=$1;print}'
}

while true; do
    TMP_FILE="/dev/shm/status.txt.tmp"
    FINAL_FILE="/dev/shm/status.txt"

    {
        echo "Motion-front:"
        get_motion_status "/opt/racksview/var/motion-front.flg" "/opt/racksview/var/no-motion-front.flg" "/dev/shm/mdetector-front.txt"
        echo ""
        echo "Motion-back:"
        get_motion_status "/opt/racksview/var/motion-back.flg" "/opt/racksview/var/no-motion-back.flg" "/dev/shm/mdetector-back.txt"
        echo ""
        echo "Services Status:"
        for svc in gstreamer-front.service mdetector-front.service vrecorder-front.service gstreamer-back.service mdetector-back.service vrecorder-back.service; do
            echo "$svc: $(get_service_status "$svc")"
        done
        echo ""
        echo "Hostname: $(get_hostname)"
        echo "IP Address: $(get_ip_address)"
        echo "OS: $(get_os_version)"
        echo "Kernel: $(get_kernel_version)"
        echo "Uptime: $(get_uptime)"
        echo "CPU Load: $(get_CPU_usage)"
        echo "CPU Temp: $(get_cpu_temp)"
        echo "RAM Used: $(get_ram_usage)"
        echo "Main storage Used: $(get_disk_usage "/opt/racksview")"
        echo "Video storage Used: $(get_disk_usage "/opt/racksview/var/video")"
        echo ""
        echo "Radio Status: "
        get_radio_status
    } > "$TMP_FILE"

    mv -f "$TMP_FILE" "$FINAL_FILE"

    /usr/bin/python3 /opt/racksview/src/display_update.py

    sleep 10
done
