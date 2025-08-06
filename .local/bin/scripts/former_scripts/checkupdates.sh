#!/bin/bash

case $BUTTON in
    1) alacritty -e yay -Syu;;
esac

icon=""

echo " $icon $(yay -Qu | wc -l) "
