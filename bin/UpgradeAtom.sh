#!/bin/bash

cd /tmp

# wget https://atom.io/download/deb -O atom.deb
wget https://atom.io/download/deb?channel=beta -O atom.deb

sudo dpkg -i atom.deb


