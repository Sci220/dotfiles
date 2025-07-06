#!/bin/bash

CARD="card4"
PCM="pcm0p"
SUB="sub0"
FILE="/proc/asound/$CARD/$PCM/$SUB/hw_params"

if [ -f "$FILE" ]; then
    FORMAT=$(grep ^format "$FILE" | awk '{print $2}')
    RATE=$(grep ^rate "$FILE" | awk '{print $2}')
    BITS=$(echo "$FORMAT" | grep -o '[0-9]\+')

    # Convert rate to human-readable (e.g., 96000 → 96kHz)
    if [[ $RATE -ge 1000 ]]; then
        RATE_HR="$((RATE / 1000))kHz"
    else
        RATE_HR="${RATE}Hz"
    fi

    if [[ "$FORMAT" == "S32_LE" && "$RATE" == "96000" ]]; then
        echo "{\"text\": \"🎵 $RATE_HR / ${BITS}-bit\", \"class\": \"bitperfect\"}"
    else
        echo "{\"text\": \"🎵 $RATE_HR / ${BITS}-bit\", \"class\": \"resampled\"}"
    fi
else
    echo '{"text": "🔇 No Output", "class": "nooutput"}'
fi
