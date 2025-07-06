#!/bin/bash

# Enhanced CachyOS Package Updater for Waybar
# File: updates.sh
# Optimized for CachyOS with AUR support, smart caching, and click actions

# Configuration
CACHE_DIR="$HOME/.cache/waybar-updates"
CACHE_FILE="$CACHE_DIR/updates.json"
LAST_CHECK="$CACHE_DIR/last_check"
NOTIFICATION_FILE="$CACHE_DIR/last_notification"
LOCK_FILE="/tmp/updates-waybar.lock"

# Intervals (in seconds)
CHECK_INTERVAL=1800  # 30 minutes
NOTIFICATION_COOLDOWN=3600  # 1 hour between notifications
FORCE_CHECK_INTERVAL=21600  # 6 hours for forced online check

# Icons (keeping your style)
ICON_UPDATED=" ✓"
ICON_PENDING=" "
ICON_ERROR=" !"
ICON_CHECKING=" ..."

# Create cache directory
mkdir -p "$CACHE_DIR"

# Lock mechanism to prevent multiple instances
acquire_lock() {
    exec 200>"$LOCK_FILE"
    flock -n 200 || exit 1
}

release_lock() {
    flock -u 200
}

# Cleanup on exit
trap 'release_lock; exit' EXIT
acquire_lock

# Get current timestamp
get_timestamp() {
    date +%s
}

# Check if we need to run update check
should_check_updates() {
    local current_time=$(get_timestamp)
    local last_check_time=0

    if [[ -f "$LAST_CHECK" ]]; then
        last_check_time=$(cat "$LAST_CHECK")
    fi

    # Force check if it's been too long or if file doesn't exist
    if [[ $((current_time - last_check_time)) -gt $FORCE_CHECK_INTERVAL ]] || [[ ! -f "$CACHE_FILE" ]]; then
        return 0
    fi

    # Regular check interval
    if [[ $((current_time - last_check_time)) -gt $CHECK_INTERVAL ]]; then
        return 0
    fi

    return 1
}

# Enhanced update checking for CachyOS
check_updates() {
    local official_updates=0
    local aur_updates=0
    local cachyos_updates=0
    local total_updates=0
    local error_occurred=false

    # Count official repo updates (using your preferred methods)
    if command -v checkupdates >/dev/null 2>&1; then
        # Method 1: Standard checkupdates (preferred)
        local official_list
        official_list=$(checkupdates 2>/dev/null)
        if [[ $? -eq 0 && -n "$official_list" ]]; then
            official_updates=$(echo "$official_list" | wc -l)
            # Count CachyOS-specific packages
            cachyos_updates=$(echo "$official_list" | grep -iE "(cachyos|cachy)" | wc -l)
        fi
    else
        # Method 2: Alternative for systems without pacman-contrib
        official_updates=$(pacman -Qu 2>/dev/null | wc -l)
    fi

    # If still 0, try another method (your fallback)
    if [[ "$official_updates" -eq 0 ]]; then
        official_updates=$(pacman -Qu 2>/dev/null | wc -l)
    fi

    # Count AUR updates (using paru as in your script)
    if command -v paru >/dev/null 2>&1; then
        aur_updates=$(paru -Qua 2>/dev/null | wc -l)
    elif command -v yay >/dev/null 2>&1; then
        aur_updates=$(yay -Qum 2>/dev/null | wc -l)
    fi

    # Total updates
    total_updates=$((official_updates + aur_updates))

    # Enhanced tooltip (keeping your structure but adding more info)
    local tooltip="$total_updates updates available\\nOfficial: $official_updates"
    if [[ $cachyos_updates -gt 0 ]]; then
        tooltip+=" (CachyOS: $cachyos_updates)"
    fi
    tooltip+="\\nAUR: $aur_updates\\n"
    tooltip+="\\nLast check: $(date '+%H:%M')\\n"
    tooltip+="\\nClick: Update | Right-click: Refresh | Middle-click: Details"

    # Output format (keeping your original classes and style)
    local output=""
    if [[ "$total_updates" -eq 0 ]]; then
        output='{"text": "'"$ICON_UPDATED"'", "class": "updated", "tooltip": "System is up to date\\n\\nLast check: '"$(date '+%H:%M')"'\\n\\nClick: Update | Right-click: Refresh"}'
    elif [[ "$total_updates" -lt 10 ]]; then
        output='{"text": "'"$ICON_PENDING$total_updates"'", "class": "normal", "tooltip": "'"$tooltip"'"}'
    else
        output='{"text": "'"$ICON_PENDING$total_updates"'", "class": "urgent", "tooltip": "'"$tooltip"'"}'
    fi

    # Cache the result
    echo "$output" > "$CACHE_FILE"
    echo "$(get_timestamp)" > "$LAST_CHECK"

    # Send smart notification
    send_notification "$total_updates" "$official_updates" "$aur_updates" "$cachyos_updates"

    echo "$output"
}

# Smart notification system
send_notification() {
    local total=$1
    local official=$2
    local aur=$3
    local cachyos=$4
    local current_time=$(get_timestamp)
    local last_notification=0

    if [[ -f "$NOTIFICATION_FILE" ]]; then
        last_notification=$(cat "$NOTIFICATION_FILE")
    fi

    # Only send notification if:
    # 1. There are updates
    # 2. Enough time has passed since last notification
    # 3. It's not the first run after boot
    if [[ $total -gt 0 ]] && [[ $((current_time - last_notification)) -gt $NOTIFICATION_COOLDOWN ]] && [[ -f "$NOTIFICATION_FILE" ]]; then
        local title="System Updates Available"
        local body="$total updates found"

        if [[ $cachyos -gt 0 ]]; then
            body+="\n• CachyOS packages: $cachyos"
        fi
        if [[ $official -gt 0 ]]; then
            body+="\n• Official packages: $((official - cachyos))"
        fi
        if [[ $aur -gt 0 ]]; then
            body+="\n• AUR packages: $aur"
        fi

        # Use mako for notifications
        notify-send "$title" "$body" -i "system-software-update" -t 10000 -u normal

        echo "$current_time" > "$NOTIFICATION_FILE"
    elif [[ ! -f "$NOTIFICATION_FILE" ]]; then
        # First run, just create the file without notification
        echo "$current_time" > "$NOTIFICATION_FILE"
    fi
}

# Handle click actions
handle_click() {
    case "$1" in
        "update")
            # Launch terminal with update commands (using kitty from your config)
            kitty --class="floating" --title="System Update" bash -c '
                echo "🔄 Updating CachyOS system packages..."
                echo "Press Enter to continue or Ctrl+C to cancel..."
                read -r

                if command -v paru >/dev/null 2>&1; then
                    paru -Syu
                elif command -v yay >/dev/null 2>&1; then
                    yay -Syu
                else
                    sudo pacman -Syu
                fi

                echo -e "\n✅ Update complete! Press Enter to close..."
                read -r
            ' &
            ;;
        "refresh")
            # Force refresh package databases
            rm -f "$CACHE_FILE" "$LAST_CHECK"
            check_updates
            ;;
        "list")
            # Show detailed package list using rofi (matching your workflow)
            local details=""

            if command -v checkupdates >/dev/null 2>&1; then
                local official_list=$(checkupdates 2>/dev/null)
                if [[ -n "$official_list" ]]; then
                    details+="=== Official Repository Updates ===\n$official_list\n\n"
                fi
            fi

            if command -v paru >/dev/null 2>&1; then
                local aur_list=$(paru -Qua 2>/dev/null)
                if [[ -n "$aur_list" ]]; then
                    details+="=== AUR Updates ===\n$aur_list"
                fi
            fi

            if [[ -z "$details" ]]; then
                details="No updates available"
            fi

            echo -e "$details" | rofi -dmenu -p "📦 Available Updates" -theme-str 'window {width: 800px; height: 600px;}'
            ;;
    esac
}

# Main execution
main() {
    case "${1:-}" in
        "--update"|"-u")
            handle_click "update"
            ;;
        "--refresh"|"-r")
            handle_click "refresh"
            ;;
        "--list"|"-l")
            handle_click "list"
            ;;
        "--force-check"|"-f")
            rm -f "$LAST_CHECK"
            check_updates
            ;;
        "--help"|"-h")
            echo "Enhanced CachyOS Package Updater for Waybar"
            echo "Usage: $0 [option]"
            echo "Options:"
            echo "  -u, --update      Open update terminal"
            echo "  -r, --refresh     Force refresh package databases"
            echo "  -l, --list        Show detailed package list"
            echo "  -f, --force-check Force check for updates"
            echo "  -h, --help        Show this help"
            echo "  (no option)       Check updates and output JSON for Waybar"
            ;;
        *)
            # Default: check if we need to update and return cached result
            if should_check_updates; then
                check_updates
            else
                # Return cached result
                if [[ -f "$CACHE_FILE" ]]; then
                    cat "$CACHE_FILE"
                else
                    echo '{"text": "'"$ICON_UPDATED"'", "class": "updated", "tooltip": "No updates checked yet"}'
                fi
            fi
            ;;
    esac
}

main "$@"
