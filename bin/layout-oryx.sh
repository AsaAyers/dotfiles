#!/bin/bash

set -x
SCREENS=$(xrandr | grep ' connected'| cut -d ' ' -f 1 | xargs)

if [ ! -z "$1" ]; then
    SCREENS=$1
fi

echo "SCREENS: $SCREENS"

MOBILE="eDP-1-1"
VERTICAL="DP-2"
LEFT="DP-0"

HOME_4K="$LEFT $VERTICAL $MOBILE"

if [ "$SCREENS" = "MOBILE" ]; then
	SCREENS=$MOBILE
fi


if [ "$SCREENS" = "$HOME_4K" ]; then
  xrandr \
    --output $MOBILE --mode 1920x1080 --pos 6000x2760 --rotate normal \
    --output HDMI-0 --off \
    --output DP-3 --off \
    --output $VERTICAL --mode 3840x2160 --pos 3840x0 --rotate right \
    --output DP-1 --off \
    --output $LEFT --mode 3840x2160 --pos 0x1680 --rotate normal --primary
fi

if [ "$SCREENS" = "$LEFT $MOBILE" ]; then
  xrandr \
    --output $MOBILE --mode 1920x1080 --pos 3840x1080 --rotate normal \
    --output HDMI-0 --off \
    --output DP-3 --off \
    --output $VERTICAL --off \
    --output DP-1 --off \
    --output $LEFT --mode 3840x2160 --pos 0x1680 --rotate normal --primary
fi

if [ "$SCREENS" = "$MOBILE" ]; then
  xrandr \
    --output $MOBILE --mode 1920x1080 --pos 0x0 --rotate normal --primary \
    --output HDMI-0 --off \
    --output DP-3 --off \
    --output $VERTICAL --off \
    --output DP-1 --off \
    --output $LEFT --off
fi


