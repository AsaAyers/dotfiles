#!/bin/bash

cd $HOME/.config/i3
lock_image=./wallpaper

# Synchronize cached writes to persistent storage
sync

printf '{"ts": %s, "className": "%s","title": ""}\n' $(date "+%s") "LOCK" >> ~/personal_events.log
# printf '{"ts": %s, "className": "%s","title": ""}\n' $(date "+%s") "LOCK" >> ~/focus-tracker.log
# date "+%s LOCK : none" >> ~/personal_events.log
if which i3lock-fancy >/dev/null; then
  xset dpms force off
  i3lock-fancy --pixelate
else
  # Lock screen displaying this image.
  ./i3lock-multimonitor/lock -i $lock_image -a "--nofork --pointer=default --ignore-empty-password --show-failed-attempts"
fi
printf '{"ts": %s, "className": "%s","title": ""}\n' $(date "+%s") "UNLOCK" >> ~/personal_events.log
# printf '{"ts": %s, "className": "%s","title": ""}\n' $(date "+%s") "UNLOCK" >> ~/focus-tracker.log
# date "+%s UNLOCK : none" >> ~/personal_events.log
