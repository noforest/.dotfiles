#!/bin/sh

exec >/home/for/.xinitrc.log 2>&1
picom -b &
dunst &
# feh --bg-fill ~/Pictures/from_twitter/IMG_7741.JPG &
# feh --bg-fill Pictures/Wallpapers/a_ski_lift_with_a_chair_in_the_air.jpg &
# feh --bg-fill ~/Pictures/Wallpapers/purple_mountain.JPG &

export WALLPAPER="/home/for/Pictures/Wallpapers/banshee_of_inisherin.png"
feh --bg-fill "$WALLPAPER" &

xset r rate 250 50 &

clipster -d -f ~/.config/clipster/clipster.ini &
export MOZ_GTK_TITLEBAR_DECORATION=none

### keyboard fr personalisé (que certaines touches XF86)
### xkbcomp -I$HOME/.xkb $HOME/.xkb/base.xkb $DISPLAY

####### ANCIEN #######
# ~~~~~~~~~~ DANS /etc/X11/xorg.conf.d/00-keyboard.conf ~~~~~~~~~~~
# setxkbmap -option caps:escape &
# setxkbmap -layout fr -option caps:escape &
######################

xinput --set-prop "ELAN2204:00 04F3:3109 Touchpad" "libinput Scrolling Pixel Distance" 30 &
xinput --set-prop "pointer:Logitech K400 Plus" "libinput Natural Scrolling Enabled" 1 &
libinput-gestures-setup restart &
dwmblocks & 
xset dpms 1800 0 0 &       #standby/suspend/off
xss-lock -- slock &

xautolock -time 35 -locker "systemctl suspend" -detectsleep &

exec dwm
