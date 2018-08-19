#!/bin/bash

if ! which git >/dev/null ; then
  sudo apt install git

fi

if [ ! -d $HOME/.cfg ]; then
  git clone --bare https://github.com/AsaAyers/dotfiles.git $HOME/.cfg
fi
function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no

config submodule update --init --recursive

config remote set-url origin git@github.com:AsaAyers/dotfiles.git

