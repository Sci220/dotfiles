#!/bin/bash

# 🧠 Configurable thresholds
warning=80
critical=90
mounts="/ /home"

# 🧾 Initialize JSON output
output=''

for mount in $mounts; do
    if df_output=$(df -h -P -l "$mount" 2>/dev/null | tail -1); then
        filesystem=$(echo "$df_output" | awk '{print $1}')
        size=$(echo "$df_output" | awk '{print $2}')
        used=$(echo "$df_output" | awk '{print $3}')
        avail=$(echo "$df_output" | awk '{print $4}')
        usep=$(echo "$df_output" | awk '{print $5}' | tr -d '%')
        mountpoint=$(echo "$df_output" | awk '{print $6}')

        icon="🖴 "
        text="$icon ${usep}%"
        tooltip="Filesystem: $filesystem\nSize: $size\nUsed: $used\nAvailable: $avail\nUse%: ${usep}%\nMounted on: $mountpoint"

        # Decide class
        class=""
        if [ "$usep" -ge "$critical" ]; then
            class="critical"
        elif [ "$usep" -ge "$warning" ]; then
            class="warning"
        fi

        output="{\"text\":\"$text\",\"tooltip\":\"$tooltip\",\"percentage\":$usep,\"class\":\"$class\"}"
        break
    fi
done

# Fallback if no mount could be read
if [ -z "$output" ]; then
    output="{\"text\":\"🚫\",\"tooltip\":\"No mount point found\",\"class\":\"critical\"}"
fi

echo "$output"
