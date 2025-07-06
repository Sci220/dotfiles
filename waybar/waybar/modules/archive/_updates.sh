#!/bin/bash

# Count official repo updates (try multiple methods for CachyOS)
if command -v pacman-contrib >/dev/null 2>&1; then
    # Method 1: Standard checkupdates
    official_updates=$(checkupdates 2>/dev/null | wc -l)
else
    # Method 2: Alternative for systems without pacman-contrib
    official_updates=$(pacman -Qu 2>/dev/null | wc -l)
fi

# If still 0, try another method
if [ "$official_updates" -eq 0 ]; then
    official_updates=$(pacman -Qu 2>/dev/null | wc -l)
fi

# Count AUR updates
aur_updates=$(paru -Qua 2>/dev/null | wc -l)

# Total updates
total_updates=$((official_updates + aur_updates))

# Output format for waybar
if [ "$total_updates" -eq 0 ]; then
    echo '{"text": " ✓", "class": "updated", "tooltip": "System is up to date"}'
elif [ "$total_updates" -lt 10 ]; then
    echo "{\"text\": \" $total_updates\", \"class\": \"normal\", \"tooltip\": \"$total_updates updates available\\nOfficial: $official_updates\\nAUR: $aur_updates\"}"
else
    echo "{\"text\": \" $total_updates\", \"class\": \"urgent\", \"tooltip\": \"$total_updates updates available\\nOfficial: $official_updates\\nAUR: $aur_updates\"}"
fi
