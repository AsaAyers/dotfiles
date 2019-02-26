#!/usr/bin/env bash

# This script is based on
# https://www.reddit.com/r/i3wm/comments/4d4luc/how_to_focus_the_last_window/
slack=

xprop -root -spy _NET_ACTIVE_WINDOW | while :
do
    read line
    id=$(echo "$line" | awk -F' ' '{printf $NF}')

    if xprop -id $id | grep WM_CLASS | grep Slack; then
      # https://github.com/i3/i3/issues/2971#issuecomment-365268904
      slack=$id
      echo "Slack: $slack"
    elif [ ! -z "$slack" ]; then
      echo "Slack lost focus"
      i3-msg "[class=Slack id=$slack] move scratchpad"
      slack=
    else
      echo "other"
    fi
done
