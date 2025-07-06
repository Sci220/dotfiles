#!/bin/bash

# Check if Quod Libet is running
if pgrep -x "quodlibet" > /dev/null; then
    # Get song information using quodlibet's CLI command
    song_info=$(quodlibet --print-playing '<artist> - <title>')

    if [ -n "$song_info" ]; then
        # Display song information
        echo "{\"text\":\"♪ $song_info\", \"alt\":\"Quod Libet\", \"tooltip\":\"$song_info\"}"
    else
        # No song playing
        echo "{\"text\":\"♪ No song playing\", \"alt\":\"Quod Libet\", \"tooltip\":\"No song playing\"}"
    fi
else
    # Quod Libet is not running
    echo "{\"text\":\"♪ Quod Libet not running\", \"alt\":\"Quod Libet\", \"tooltip\":\"Quod Libet is not running\"}"
fi
