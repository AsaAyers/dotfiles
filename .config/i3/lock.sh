#!/bin/bash

cd /home/asa/.config/i3
lock_image=~/Pictures/wallpaper.jpg

# Synchronize cached writes to persistent storage
sync

# Lock screen displaying this image.
./i3lock-multimonitor/lock -i $lock_image -a "--nofork --pointer=default --ignore-empty-password --show-failed-attempts"
