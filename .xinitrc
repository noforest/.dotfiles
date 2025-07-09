#!/bin/sh
picom &
dunst &
# feh --bg-fill ~/Pictures/from_twitter/IMG_7741.JPG &
# feh --bg-fill Pictures/Wallpapers/a_ski_lift_with_a_chair_in_the_air.jpg &
# feh --bg-fill ~/Pictures/Wallpapers/purple_mountain.JPG &

export WALLPAPER="/home/for/Pictures/Wallpapers/banshee_of_inisherin.png"
feh --bg-fill "$WALLPAPER" &

xset r rate 250 50 &
# xmodmap ~/.Xmodmap &
clipster -d -f ~/.config/clipster/clipster.ini &
export MOZ_GTK_TITLEBAR_DECORATION=none
setxkbmap -option caps:escape &
xinput --set-prop "ELAN2204:00 04F3:3109 Touchpad" "libinput Scrolling Pixel Distance" 30 &
xinput --set-prop "pointer:Logitech K400 Plus" "libinput Natural Scrolling Enabled" 1 &
libinput-gestures-setup restart &
dwmblocks & 
# xset dpms 600 &
xss-lock -- slock &
exec dwm 2> ~/.dwm.log



# export WALLPAPER="/home/for/Pictures/Wallpapers/banshee_of_inisherin.png"
# feh --bg-fill "$WALLPAPER" &
# ~/.xprofile_autostart.sh
#
# xss-lock -- ~/.local/bin/scripts/lock_and_refresh.sh &
# # xss-lock -- slock &
#
# dwmblocks & 
# exec dwm 2> ~/.dwm.log
