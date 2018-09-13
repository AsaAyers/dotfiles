#!/bin/bash
# https://github.com/i3/i3/issues/2971#issuecomment-365268904
XDT=/usr/bin/xdotool

WINDOW=`$XDT getwindowfocus`

# this brings in variables WIDTH and HEIGHT
eval `xdotool getwindowgeometry --shell $WINDOW`

TX=`expr $WIDTH / 2`
TY=`expr $HEIGHT / 2`

$XDT mousemove -window $WINDOW $TX $TY


