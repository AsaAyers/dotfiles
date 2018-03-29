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

if ! which firefox &>/dev/null; then
  echo "missing ubuntu-make"
  echo "snap install firefox"
fi

if ! which atom &>/dev/null; then
  echo "missing ubuntu-make"
  echo "snap install --classic atom"
fi

if ! which slack &>/dev/null; then
  echo "missing ubuntu-make"
  echo "snap install --classic slack"
fi

if ! which hub; then
  echo "Missing hub command"
  echo "https://github.com/github/hub/releases"
fi

if ! which ubuntu-make.umake &>/dev/null; then
  echo "missing ubuntu-make"
  echo "snap install --classic ubuntu-make"
fi


if ! which cdiff &>/dev/null; then
  echo "missing color-diff"
  echo "sudo apt install color-diff"
fi


