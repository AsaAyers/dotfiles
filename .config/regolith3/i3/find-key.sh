#!/bin/bash


FILES=$(i3 --moreversion | egrep "main|included" | cut -d ' ' -f 3)


echo $FILES | xargs grep -i --color $1 ~/.config/regolith3/Xresources
