#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
export MONITOR=$(xrandr -q | grep primary | cut -d ' ' -f1)
echo $MONITOR
polybar primary &

OTHERS=$(xrandr -q | grep ' connected' | grep -v $MONITOR | cut -d ' ' -f1)

for MONITOR in $OTHERS; do
  echo $MONITOR
  polybar primary &
done

echo "Bars launched..."

