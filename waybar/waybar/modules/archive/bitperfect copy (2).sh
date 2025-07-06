#!/bin/bash

# Auto-detect active audio card and display format info
# This replaces your existing bitperfect.sh

# Function to format rate (Hz to kHz)
format_rate() {
    local rate=$1
    if [[ $rate -ge 1000 ]]; then
        # Convert to kHz and remove trailing zeros
        local khz=$(echo "scale=1; $rate / 1000" | bc)
        # Remove .0 if it's a whole number
        khz=$(echo "$khz" | sed 's/\.0$//')
        echo "${khz}kHz"
    else
        echo "${rate}Hz"
    fi
}

# Function to check if a card is active
check_card() {
    local card=$1
    local params=$(cat /proc/asound/card$card/pcm0p/sub0/hw_params 2>/dev/null)

    if [[ -n "$params" && "$params" != *"closed"* ]]; then
        local rate=$(echo "$params" | grep '^rate:' | awk '{print $2}')
        local bits=$(echo "$params" | grep '^format:' | sed -n 's/.*S\([0-9]*\)_LE/\1/p')

        if [[ -n "$rate" && -n "$bits" ]]; then
            # Get card name for display
            local card_name=$(cat /proc/asound/card$card/id 2>/dev/null || echo "Card$card")

            # Format the rate
            local formatted_rate=$(format_rate "$rate")

            # Check for bit-perfect conditions (you can adjust these values)
            if [[ "$rate" == "96000" && "$bits" == "32" ]]; then
                echo "{\"text\": \"🧊 ${card_name} ${formatted_rate}/${bits}bit\", \"class\": \"bitperfect-glow\", \"tooltip\": \"Bit-perfect: ${card_name} at ${formatted_rate} ${bits}-bit\"}"
            else
                echo "{\"text\": \"🔊 ${card_name} ${formatted_rate}/${bits}bit\", \"class\": \"bitperfect-soft\", \"tooltip\": \"Active: ${card_name} at ${formatted_rate} ${bits}-bit\"}"
            fi
            return 0
        fi
    fi
    return 1
}

# Auto-detect active card by checking all available cards
for card_path in /proc/asound/card*/; do
    if [[ -d "$card_path" ]]; then
        card_num=$(basename "$card_path" | sed 's/card//')
        if check_card "$card_num"; then
            exit 0
        fi
    fi
done

# No active output found
echo '{"text": "🔇 No Output", "class": "nooutput", "tooltip": "No active audio output detected"}'
