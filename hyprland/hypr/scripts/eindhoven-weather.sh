#!/bin/bash

# Eindhoven Airport Weather Script for Hyprlock
# Optimized for lockscreen display

cachedir=~/.cache/hyprlock
cachefile="eindhoven-weather"

if [ ! -d $cachedir ]; then
    mkdir -p $cachedir
fi

if [ ! -f $cachedir/$cachefile ]; then
    touch $cachedir/$cachefile
fi

# Save current IFS
SAVEIFS=$IFS
IFS=$'\n'

# Cache for 30 minutes (1800 seconds) to avoid API rate limits on lockscreen
cacheage=$(($(date +%s) - $(stat -c '%Y' "$cachedir/$cachefile" 2>/dev/null || echo 0)))
if [ $cacheage -gt 1800 ] || [ ! -s $cachedir/$cachefile ]; then
    # Use Eindhoven airport code (EIN) for more accurate local weather
    data=($(curl -s "https://en.wttr.in/EIN?0qnT" 2>/dev/null))
    if [ ${#data[@]} -ge 3 ]; then
        echo "${data[0]}" | cut -f1 -d, > $cachedir/$cachefile
        echo "${data[1]}" | sed -E 's/^.{15}//' >> $cachedir/$cachefile
        echo "${data[2]}" | sed -E 's/^.{15}//' >> $cachedir/$cachefile
    else
        # Fallback if API fails
        echo "Eindhoven" > $cachedir/$cachefile
        echo "Weather unavailable" >> $cachedir/$cachefile
        echo "-- °C" >> $cachedir/$cachefile
    fi
fi

weather=($(cat $cachedir/$cachefile 2>/dev/null))

# Restore IFS
IFS=$SAVEIFS

# Handle empty weather data
if [ ${#weather[@]} -lt 3 ]; then
    echo "🌤️ Weather unavailable"
    exit 0
fi

temperature=$(echo "${weather[2]}" | sed -E 's/([[:digit:]]+)\.\./\1 to /g' | sed 's/°C.*$/°C/')
condition_text=$(echo "${weather[1]##*,}" | tr '[:upper:]' '[:lower:]' | xargs)

# Weather condition mapping with appropriate emojis
case "$condition_text" in
    "clear" | "sunny")
        condition="☀️"
        ;;
    "partly cloudy")
        condition="⛅"
        ;;
    "cloudy" | "overcast")
        condition="☁️"
        ;;
    "mist" | "fog" | "freezing fog")
        condition="🌫️"
        ;;
    *"light rain"* | *"drizzle"* | *"patchy rain"*)
        condition="🌦️"
        ;;
    *"moderate rain"* | *"heavy rain"* | *"rain shower"* | "rain")
        condition="🌧️"
        ;;
    *"snow"* | *"sleet"* | *"freezing"*)
        condition="❄️"
        ;;
    *"thunder"*)
        condition="⛈️"
        ;;
    *"wind"* | *"windy"*)
        condition="💨"
        ;;
    *)
        condition="🌤️"
        ;;
esac

# Format for lockscreen display - concise but informative
echo "$condition $temperature"
