#!/bin/sh

# Activate screensaver in the top left
# Disable screensaver with bottom left
exec xautolock -time 10 \
  -noclose \
  -detectsleep \
  -locker "/home/asa/.config/i3/lock.sh" \
  -notify 30 \
  -notifier "notify-send -u critical -t 10000 -- 'LOCKING screen in 30 seconds'"

  # -cornerdelay 1 \
  # -corners +0-0 \
