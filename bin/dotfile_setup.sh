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

sudo apt install -y \
  blueman \
  colordiff \
  feh \
  gnome-tweaks \
  i3 \
  i3lock-fancy \
  libglib2.0-dev libgtk-3-dev libnotify-dev libpulse-dev libx11-dev autoconf automake pkg-config \ # pa-applet dependencies
  meld \
  numlockx \
  snapd \
  vim \
  xautolock \
  xserver-xorg-input-synaptics

# https://github.com/drduh/YubiKey-Guide#21-install---linux
sudo apt install -y \
    gnupg2 gnupg-agent pinentry-curses scdaemon pcscd yubikey-personalization libusb-1.0-0-dev


sudo snap install --classic atom
sudo snap install --classic slack
sudo snap install --classic ubuntu-make

apm install \
  atom-ide-ui \
  js-hyperclick \
  linter-eslint \
  react \
  vim-mode-plus ex-mode

if ! which pa-applet >/dev/null 2>&1; then
	cd $HOME/pa-applet
	./autogen.sh
	./configure
	make
	sudo make install
fi
