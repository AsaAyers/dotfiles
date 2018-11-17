#!/bin/bash

set -x
SCREENS=$(xrandr | grep ' connected'| cut -d ' ' -f 1 | xargs)

if [ ! -z "$1" ]; then
    SCREENS=$1
fi

echo "SCREENS: $SCREENS"

if upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E state | grep discharging -q; then
  system76-power profile battery
else
  system76-power profile performance
fi

MOBILE="DP-0"
AT_HOME="$MOBILE DP-1"
HOME_4K="$MOBILE DP-1 DP-3"

if [ "$SCREENS" = "MOBILE" ]; then
	SCREENS=$MOBILE
fi

BRIGHTNESS=1.0


if [ "$SCREENS" = "$AT_HOME" ]; then
	echo "HOME"
	xrandr --dpi 220 \
		--output HDMI-0 --off \
		--output DP-4 --off \
		--output DP-3 --off \
		--output DP-2 --off \
		--output $MOBILE --mode 3840x2160 --pos 0x0 --rotate normal --scale 1x1 \
		--output DP-1 --auto --pos 3840x0 --rotate normal --scale 1x1 --primary 
fi



if [ "$SCREENS" = "$HOME_4K" ]; then
	xrandr \
		--output $MOBILE --mode 3840x2160 --scale 1x1 --pos 6000x1680 \
		--output DP-1 --auto --pos 3840x0 --rotate right --primary \
		--output DP-3 --auto --pos 0x1680 

fi



if [ "$SCREENS" = "$MOBILE" ]; then
	echo "MOBILE WAT?"

        xrandr --dpi 220 --fb 1920x1080 --output $MOBILE --auto --scale 0.5x0.5 --pos 0x0 --primary
	SCREENS=$(xrandr | grep ' connected'| cut -d ' ' -f 1 | xargs)
	for X in $SCREENS; do 
		if [ "$X" != "$MOBILE" ]; then 
			xrandr --output $X --off
		fi
	done
fi

echo "screens: $SCREENS"
echo "mobile: $MOVILE"


