#!/bin/bash

# Enhanced Power Menu with better icons and styling
# Make sure you have nerd fonts installed for proper icon display

# Color variables for consistency
MAUVE="#cba6f7"
TEXT="#cdd6f4"
BASE="#1e1e2e"

# Options with improved icons and spacing
options="󰐥  Shutdown
󰜉  Reboot
󰒲  Suspend
󰍃  Logout
󰜺  Cancel"

# Enhanced Rofi CMD with message
chosen=$(echo -e "$options" | rofi \
    -dmenu \
    -i \
    -p "" \
    -mesg "Choose your pill" \
    -theme ~/.config/rofi/powermenu.rasi \
    -selected-row 0 \
    -no-fixed-num-lines \
    -markup-rows)

# Process selection
case "$chosen" in
    "󰐥  Shutdown")
        notify-send "Power Menu" "Shutting down..." -i system-shutdown
        sleep 1
        systemctl poweroff
        ;;
    "󰜉  Reboot")
        notify-send "Power Menu" "Rebooting..." -i system-reboot
        sleep 1
        systemctl reboot
        ;;
    "󰒲  Suspend")
        notify-send "Power Menu" "Suspending..." -i system-suspend
        systemctl suspend
        ;;
    "󰍃  Logout")
        notify-send "Power Menu" "Logging out..." -i system-log-out
        sleep 1
        hyprctl dispatch exit
        ;;
    "󰜺  Cancel"|"")
        notify-send "Power Menu" "Cancelled" -i dialog-information
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
