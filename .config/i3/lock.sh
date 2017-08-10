#!/bin/sh -e

# Take a screenshot
scrot ~/.config/i3/screen_locked.png
# Blur the screenshot

convert ~/.config/i3/screen_locked.png \
  -blur 0x6 \
  -fill red \
  -font Ubuntu \
  -gravity center \
  -pointsize 96 \
  -annotate 0 "Screen Locked" \
  /tmp/screen_locked.png



rm ~/.config/i3/screen_locked.png


# Lock screen displaying this image.
# date "+%s LOCK" >> ~/personal_events.log
i3lock --nofork --ignore-empty-password --image=/tmp/screen_locked.png --dpms --show-failed-attempts
# date "+%s UNLOCK" >> ~/personal_events.log
