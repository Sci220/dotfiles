#!/bin/bash

# Simplified CachyOS Package Updater for Waybar
CACHE_DIR="$HOME/.cache/waybar-updates"
CACHE_FILE="$CACHE_DIR/updates.json"
LAST_CHECK="$CACHE_DIR/last_check"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Check if we should update (every 30 minutes)
should_check() {
    if [[ ! -f "$LAST_CHECK" ]]; then
        return 0
    fi

    local current_time=$(date +%s)
    local last_check_time=$(cat "$LAST_CHECK")
    local diff=$((current_time - last_check_time))

    # Check every 30 minutes (1800 seconds)
    [[ $diff -gt 1800 ]]
}

# Check for updates
check_updates() {
    local official_updates=0
    local aur_updates=0

    # Check official updates
    if command -v checkupdates >/dev/null 2>&1; then
        official_updates=$(checkupdates 2>/dev/null | wc -l)
    else
        official_updates=$(pacman -Qu 2>/dev/null | wc -l)
    fi

    # Check AUR updates
    if command -v paru >/dev/null 2>&1; then
        aur_updates=$(paru -Qua 2>/dev/null | wc -l)
    fi

    local total_updates=$((official_updates + aur_updates))

    # Create output
    local output=""
    local tooltip="Updates: $total_updates\\nOfficial: $official_updates\\nAUR: $aur_updates\\n\\nClick to update"

    if [[ $total_updates -eq 0 ]]; then
        output='{"text": "✓", "class": "updated", "tooltip": "System up to date"}'
    elif [[ $total_updates -lt 100 ]]; then
        output='{"text": "'"$total_updates"'", "class": "normal", "tooltip": "'"$tooltip"'"}'
    else
        output='{"text": "'"$total_updates"'", "class": "urgent", "tooltip": "'"$tooltip"'"}'
    fi

    # Cache result
    echo "$output" > "$CACHE_FILE"
    echo "$(date +%s)" > "$LAST_CHECK"

    echo "$output"
}

# Show updates list in rofi
show_updates_list() {
    local details=""
    local official_list=""
    local aur_list=""

    # Get official updates
    if command -v checkupdates >/dev/null 2>&1; then
        official_list=$(checkupdates 2>/dev/null)
    else
        official_list=$(pacman -Qu 2>/dev/null)
    fi

    # Get AUR updates
    if command -v paru >/dev/null 2>&1; then
        aur_list=$(paru -Qua 2>/dev/null)
    fi

    # Build the list
    if [[ -n "$official_list" ]]; then
        details+="=== Official Repository Updates ===\n$official_list\n\n"
    fi

    if [[ -n "$aur_list" ]]; then
        details+="=== AUR Updates ===\n$aur_list"
    fi

    if [[ -z "$details" ]]; then
        details="No updates available\n\nSystem is up to date! ✓\n\nLast check: $(date '+%H:%M on %b %d')\n\nPress Escape to close"
    fi

    # Show in rofi
    echo -e "$details" | rofi -dmenu -p "📦 System Updates" \
        -theme-str 'window {width: 900px; height: 400px;}' \
        -theme-str 'listview {lines: 15;}' \
        -theme-str 'element {padding: 8px;}' \
        -theme-str 'inputbar {enabled: false;}' \
        -no-custom -markup-rows -mesg "System Update Status"
}

# Main execution
if [[ "$1" == "--update" || "$1" == "-u" ]]; then
    kitty --class="floating" --title="System Update" bash -c '
        echo "🔄 Updating system packages..."
        if command -v paru >/dev/null 2>&1; then
            paru -Syu
        else
            sudo pacman -Syu
        fi
        echo "✅ Update complete! Press Enter to close..."
        read -r
    ' &
elif [[ "$1" == "--refresh" || "$1" == "-r" ]]; then
    rm -f "$CACHE_FILE" "$LAST_CHECK"
    check_updates
elif [[ "$1" == "--list" || "$1" == "-l" ]]; then
    show_updates_list
else
    # Default: check updates
    if should_check || [[ ! -f "$CACHE_FILE" ]]; then
        check_updates
    else
        cat "$CACHE_FILE"
    fi
fi
