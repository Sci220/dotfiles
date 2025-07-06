#!/bin/bash

# Enhanced bitperfect audio monitor script
# Auto-detects active audio cards with improved functionality

# Configuration - easily adjustable
UPDATE_INTERVAL=2                                          # For daemon mode (seconds)
LOG_FILE="/tmp/bitperfect.log"                            # Optional logging

# Function to log events (optional)
log_event() {
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

# Function to format rate (Hz to kHz)
format_rate() {
    local rate=$1
    if [[ $rate -ge 1000 ]]; then
        local khz=$(echo "scale=1; $rate / 1000" | bc)
        khz=$(echo "$khz" | sed 's/\.0$//')
        echo "${khz}kHz"
    else
        echo "${rate}Hz"
    fi
}

# Simple bit-perfect detection (like original)
is_bitperfect() {
    local rate=$1
    local bits=$2

    # Original simple check - adjust these values as needed
    if [[ "$rate" == "96000" && "$bits" == "32" ]]; then
        return 0
    fi
    return 1
}

# Get audio format details with enhanced parsing
get_audio_details() {
    local card=$1
    local hw_params_file="/proc/asound/card$card/pcm0p/sub0/hw_params"

    if [[ ! -r "$hw_params_file" ]]; then
        return 1
    fi

    local params=$(cat "$hw_params_file" 2>/dev/null)

    if [[ -z "$params" || "$params" == *"closed"* ]]; then
        return 1
    fi

    # Enhanced parsing
    local rate=$(echo "$params" | grep '^rate:' | awk '{print $2}')
    local format_line=$(echo "$params" | grep '^format:')
    local bits=$(echo "$format_line" | sed -n 's/.*S\([0-9]*\)_LE/\1/p')
    local channels=$(echo "$params" | grep '^channels:' | awk '{print $2}')

    # Additional format detection for DSD, etc.
    local format_type="PCM"
    if echo "$format_line" | grep -q "DSD"; then
        format_type="DSD"
    elif echo "$format_line" | grep -q "FLOAT"; then
        format_type="FLOAT"
    fi

    if [[ -n "$rate" && -n "$bits" ]]; then
        echo "$rate|$bits|$channels|$format_type"
        return 0
    fi

    return 1
}

# Get enhanced card information
get_card_info() {
    local card=$1
    local card_name=$(cat /proc/asound/card$card/id 2>/dev/null || echo "Card$card")

    # Try to get more descriptive name
    if [[ -r "/proc/asound/card$card/usbid" ]]; then
        local usb_info=$(cat /proc/asound/card$card/usbid 2>/dev/null)
        # Parse USB info for better naming if needed
    fi

    # Get driver info
    local driver=$(cat /proc/asound/card$card/pcm0p/info 2>/dev/null | grep '^name:' | cut -d':' -f2- | xargs)

    echo "$card_name|$driver"
}

# Check if a card is active (simplified like original)
check_card() {
    local card=$1
    local params=$(cat /proc/asound/card$card/pcm0p/sub0/hw_params 2>/dev/null)

    if [[ -n "$params" && "$params" != *"closed"* ]]; then
        local rate=$(echo "$params" | grep '^rate:' | awk '{print $2}')
        local bits=$(echo "$params" | grep '^format:' | sed -n 's/.*S\([0-9]*\)_LE/\1/p')

        if [[ -n "$rate" && -n "$bits" ]]; then
            # Get card name for display
            local card_name=$(cat /proc/asound/card$card/id 2>/dev/null || echo "Card$card")
            local formatted_rate=$(format_rate "$rate")

            # Simple bit-perfect detection like original
            if is_bitperfect "$rate" "$bits"; then
                echo "{\"text\": \"🧊 ${card_name} ${formatted_rate}/${bits}bit\", \"class\": \"bitperfect-glow\", \"tooltip\": \"Bit-perfect: ${card_name} at ${formatted_rate} ${bits}-bit\"}"
            else
                echo "{\"text\": \"🔊 ${card_name} ${formatted_rate}/${bits}bit\", \"class\": \"bitperfect-orange\", \"tooltip\": \"Active: ${card_name} at ${formatted_rate} ${bits}-bit\"}"
            fi
            return 0
        fi
    fi
    return 1
}

# Multiple card detection with priority handling
detect_active_card() {
    local active_cards=()
    local results=()

    # Check all cards and collect active ones
    for card_path in /proc/asound/card*/; do
        if [[ -d "$card_path" ]]; then
            card_num=$(basename "$card_path" | sed 's/card//')
            local result=$(check_card "$card_num" 2>/dev/null)
            if [[ $? -eq 0 && -n "$result" ]]; then
                active_cards+=("$card_num")
                results+=("$result")
            fi
        fi
    done

    # Return priority card (highest number, typically USB/external)
    if [[ ${#results[@]} -gt 0 ]]; then
        echo "${results[-1]}"  # Last (highest numbered) card
        return 0
    fi

    return 1
}

# Command line argument handling
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --daemon    Run continuously (for status bars)"
        echo "  --log       Enable logging to $LOG_FILE"
        echo "  --all       Show all active cards"
        echo "  --test      Test mode with verbose output"
        echo "  --help      Show this help"
        exit 0
        ;;
    --daemon)
        while true; do
            result=$(detect_active_card)
            if [[ $? -eq 0 ]]; then
                echo "$result"
            else
                echo '{"text": "🔇 No Output", "class": "nooutput", "tooltip": "No active audio output detected"}'
            fi
            sleep "$UPDATE_INTERVAL"
        done
        ;;
    --log)
        ENABLE_LOGGING=true
        ;&  # Fall through
    --all)
        # Show all active cards (for debugging)
        found_any=false
        for card_path in /proc/asound/card*/; do
            if [[ -d "$card_path" ]]; then
                card_num=$(basename "$card_path" | sed 's/card//')
                if check_card "$card_num"; then
                    found_any=true
                fi
            fi
        done
        if [[ "$found_any" != "true" ]]; then
            echo '{"text": "🔇 No Output", "class": "nooutput", "tooltip": "No active audio output detected"}'
        fi
        ;;
    --test)
        echo "Testing audio detection..."
        echo "Available cards:"
        ls /proc/asound/card*/ 2>/dev/null | head -5
        echo ""
        echo "Active detection:"
        "$0" --all
        ;;
    *)
        # Default behavior - multiple card detection with priority
        result=$(detect_active_card)
        if [[ $? -eq 0 ]]; then
            echo "$result"
        else
            echo '{"text": "🔇 No Output", "class": "nooutput", "tooltip": "No active audio output detected"}'
        fi
        ;;
esac
