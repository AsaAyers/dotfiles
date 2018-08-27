#!/bin/bash

set -x
SCREENS=$(xrandr | grep ' connected'| cut -d ' ' -f 1 | xargs)

if [ ! -z "$1" ]; then
    SCREENS=$1
fi

echo "SCREENS: $SCREENS"

MOBILE="DP-0"
AT_HOME="DP-0 DP-1"
HOME_4K="DP-0 DP-1 DP-3"

if [ "$SCREENS" = "MOBILE" ]; then
	SCREENS=$MOBILE
fi

BRIGHTNESS=1.0


if [ "$SCREENS" = "$AT_HOME" ]; then
	echo "HOME"
	# xrandr --output DP2-1 --off
	# xrandr --output DP2-2 --off
	# xrandr --output eDP2 --off


	xrandr --dpi 220 \
		--output HDMI-0 --off \
		--output DP-4 --off \
		--output DP-3 --off \
		--output DP-2 --off \
		--output DP-0 --primary --mode 3840x2160 --pos 0x0 --rotate normal --scale 0.5x0.5 \
		--output DP-1 --mode 1920x1200 --pos 1920x0 --rotate normal --scale 1x1




	# xrandr --output DP2-1 --off --output DP2-2 --off
	# xrandr --output eDP2 --auto

        # xrandr --output DP2-1 --auto --rotate right --pos 0x0 --brightness $BRIGHTNESS
        # xrandr --output DP2-2 --auto --rotate normal --pos 1200x720 --brightness $BRIGHTNESS
        # xrandr --output eDP2 --auto --pos 3120x840 --primary --brightness $BRIGHTNESS
fi



if [ "$SCREENS" = "$HOME_4K" ]; then
	xrandr \
		--output DP-0 --mode 3840x2160 --scale 1x1 --pos 6000x1680 \
		--output DP-1 --auto --pos 3840x0 --rotate right --primary \
		--output DP-3 --auto --pos 0x1680

fi



if [ "$SCREENS" = "$MOBILE" ]; then
	echo "MOBILE WAT?"

        xrandr --dpi 220 --fb 1920x1080 --output DP-0 --auto --scale 0.5x0.5 --pos 0x0 --primary
	SCREENS=$(xrandr | grep ' connected'| cut -d ' ' -f 1 | xargs)
	for X in $SCREENS; do 
		if [ "$X" != "DP-0" ]; then 
			xrandr --output $X --off
		fi
	done
fi

echo "screens: $SCREENS"
echo "mobile: $MOVILE"


