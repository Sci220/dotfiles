#!/usr/bin/env bash

levels=(0 15 30 45 60 75 100)
file="/tmp/.brightness_step"

# Read current index
if [[ -f "$file" ]]; then
    idx=$(cat "$file")
else
    idx=0
fi

# Increment index
idx=$(( (idx + 1) % ${#levels[@]} ))

# Set brightness
level=${levels[$idx]}
ddcutil setvcp 10 "$level"

# Save new index
echo "$idx" > "$file"
