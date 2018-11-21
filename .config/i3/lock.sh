#!/bin/bash

cd $HOME/.config/i3
lock_image=./wallpaper

# Synchronize cached writes to persistent storage
sync

date "+%s LOCK : none" >> ~/personal_events.log
if which i3lock-fancy >/dev/null; then
  i3lock-fancy --pixelate
else
  # Lock screen displaying this image.
  ./i3lock-multimonitor/lock -i $lock_image -a "--nofork --pointer=default --ignore-empty-password --show-failed-attempts"
fi
date "+%s UNLOCK : none" >> ~/personal_events.log
