#!/bin/bash

# set -euo pipefail
IFS=$'\n\t'

I3COMMANDS=$(egrep '^exec(_always)?' ~/.config/i3/config)

function findCommand() {
  echo $1 | sed -r s/"--no-startup-id\s*"//g | sed -r s/"^exec(_always)?\\s"//g | cut -d ' ' -f 1
}

for COMMAND in ${I3COMMANDS[@]}; do
  # findCommand $COMMAND
  if ! which $(findCommand $COMMAND) >/dev/null 2>&1 ; then
    true
    echo "Missing: $COMMAND"
  fi
done

if ! which hub; then
  echo "Missing hub command"
fi




