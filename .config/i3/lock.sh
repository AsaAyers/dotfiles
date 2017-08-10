#!/bin/bash

lock_image=/tmp/screen_locked.png
if [ "$HOSTNAME" == "asa-macbookpro" ]; then
  lock_image=/tmp/screen_locked.png
fi

echo "lock.sh: $lock_image"
time ~/.config/i3/screenshot.sh $lock_image
# Synchronize cached writes to persistent storage
sync

# Lock screen displaying this image.
i3lock --nofork --ignore-empty-password --image=$lock_image --show-failed-attempts
