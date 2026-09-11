#!/usr/bin/env bash

# Set your active network interface
INTERFACE="wlan2"

# Helper function to convert bytes into human-readable strings natively
format_speed() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        # Uses awk for native float math instead of bc
        awk -v b="$bytes" 'BEGIN {printf "%.1f MB/s", b/1048576}'
    elif [ "$bytes" -ge 1024 ]; then
        awk -v b="$bytes" 'BEGIN {printf "%.1f KB/s", b/1024}'
    else
        printf "%d B/s" "$bytes"
    fi
}

# Initial read
read -r d1 u1 < <(awk -v iface="$INTERFACE:" '$1==iface {print $2, $10}' /proc/net/dev)

while true; do
    sleep 1
    # Second read
    read -r d2 u2 < <(awk -v iface="$INTERFACE:" '$1==iface {print $2, $10}' /proc/net/dev)

    # Calculate bytes per second
    down_bytes=$((d2 - d1))
    up_bytes=$((u2 - u1))

    # Format into human-readable strings
    down_speed=$(format_speed "$down_bytes")
    up_speed=$(format_speed "$up_bytes")

    # Output the exact JSON structure Waybar needs
    printf '{"text": "%s ↓↑ %s", "tooltip": "Down: %s | Up: %s"}\n' \
        "$down_speed" "$up_speed" "$down_speed" "$up_speed"

    # Save current values for the next iteration
    d1=$d2
    u1=$u2
done
