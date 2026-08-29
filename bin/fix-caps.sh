#!/bin/bash

# Set capslog to off if it's on, and leave it alone if i's already off
if [[ $(xset -q | grep Caps | awk '{print $4}') == "on" ]]; then
    xdotool key Caps_Lock
fi

xmodmap -e "keycode 66 = grave asciitilde"
xmodmap -e "clear Lock"

