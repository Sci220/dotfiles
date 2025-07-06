#!/bin/bash

params=$(cat /proc/asound/card4/pcm0p/sub0/hw_params 2>/dev/null)

if [[ -z "$params" || "$params" == *"closed"* ]]; then
    echo '{"text": "🔇 No Output", "class": "nooutput"}'
    exit 0
fi

rate=$(echo "$params" | grep '^rate:' | awk '{print $2}')
bits=$(echo "$params" | grep '^format:' | sed -n 's/.*S\([0-9]*\)_LE/\1/p')

# Convert Hz to kHz with one decimal point (e.g., 44100 -> 44.1kHz)
rate_khz=$(awk "BEGIN { printf \"%.1f\", $rate / 1000 }")

if [[ -n "$rate_khz" && -n "$bits" ]]; then
    if [[ "$rate" == "96000" && "$bits" == "32" ]]; then
        echo "{\"text\": \"🧊 ${rate_khz}kHz / ${bits}-bit\", \"class\": \"bitperfect-glow\"}"
    else
        echo "{\"text\": \"🔊 ${rate_khz}kHz / ${bits}-bit\", \"class\": \"bitperfect-soft\"}"
    fi
else
    echo '{"text": "🔊 Unknown", "class": "unknown"}'
fi
