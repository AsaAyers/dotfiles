#!/bin/bash
#set -ex

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

sudo apt-add-repository --yes ppa:yubico/stable

sudo apt update

# xcb... is for polybar 
# libglib2.0-dev...pkg-config are pa-applet dependencies
sudo apt install -y \
  apt-transport-https \
  blueman \
  cmake \
  colordiff \
  compton \
  feh \
  flameshot \
  gnome-tweaks \
  i3 \
  xcb-proto python-xcbgen libxcb-image0-dev libxcb-image0  libxcb-ewmh-dev libxcb-icccm4-dev \
  libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev \
  i3lock-fancy \
  jq \
  libglib2.0-dev libgtk-3-dev libnotify-dev libpulse-dev libx11-dev autoconf automake pkg-config \
  meld \
  numlockx \
  snapd \
  vim \
  xautolock \
  xserver-xorg-input-synaptics \
  yubioath-desktop

# https://github.com/drduh/YubiKey-Guide#21-install---linux
sudo apt install -y \
    gnupg2 gnupg-agent pinentry-curses scdaemon pcscd yubikey-personalization libusb-1.0-0-dev

if ! which git-secret >/dev/null 2>&1; then
  echo "deb https://dl.bintray.com/sobolevn/deb git-secret main" | sudo tee -a /etc/apt/sources.list
  wget -qO - https://api.bintray.com/users/sobolevn/keys/gpg/public.key | sudo apt-key add -
  sudo apt-get update && sudo apt-get install git-secret
fi



which atom >/dev/null 2>&1 || sudo snap install --classic atom
which slack >/dev/null 2>&1 || sudo snap install --classic slack
which ubuntu-make.umake >/dev/null 2>&1 || sudo snap install --classic ubuntu-make


apm stars --user AsaAyers --json | jq '.[].name' > /tmp/stars.$$
apm ls --json | jq '.user[].name' > /tmp/installed.$$

NUM_INSTALLED=$(cat /tmp/stars.$$ /tmp/installed.$$ | sort | uniq -d | wc -l)
NUM_STARRED=$(cat /tmp/stars.$$ | wc -l)

if [ $NUM_INSTALLED -lt $NUM_STARRED ]; then 
	apm stars --user AsaAyers --install
fi


if ! which pa-applet >/dev/null 2>&1; then
	cd $HOME/pa-applet
	./autogen.sh
	./configure
	make
	sudo make install
fi

if ! which polybar >/dev/null 2>&1; then
	mkdir ~/polybar/build
	cd ~/polybar/build
	cmake ..
	sudo make install
fi

if ! which rustc >/dev/null 2>&1; then
	curl https://sh.rustup.rs -sSf | sh
fi
