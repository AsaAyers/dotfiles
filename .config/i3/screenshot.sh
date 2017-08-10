#!/bin/bash

source_file=$HOME/.config/i3/screen_locked.png
lock_image=$1

if [ -z "$1" ]; then
  echo "USAGE: $0 lockfile"
  exit 1
fi

# Take a screenshot
scrot $source_file

echo "screenshot.sh: $lock_image"
# Blur the screenshot
if [ "$HOSTNAME" == "asa-macbookpro" ]; then
  echo "Using ffmpeg"
  # On my macbook this takes about 1 second where convert takes about 4
  ffmpeg -loglevel quiet -y -i $source_file -vf "gblur=sigma=16" $lock_image
else
  convert $source_file \
    -blur 0x6 \
    -fill red \
    -font Ubuntu \
    -gravity center \
    -pointsize 96 \
    -annotate 0 "Screen Locked" \
    $lock_image
fi

rm $source_file
