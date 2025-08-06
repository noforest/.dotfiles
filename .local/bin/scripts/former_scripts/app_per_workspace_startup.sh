#!/bin/bash

# sleep 0.1

# echo "hello ce script s'execute bien au démarrage" >> ~/hellper.txt

# current_ws=$(hyprctl activeworkspace -j | jq '.id')
# echo $current_ws >> ~/hellper.txt

# # Workspace 1 + lancer firefox
# hyprctl dispatch workspace $current_ws
# firefox -P hyprland &
#
# # Workspace 2 + lancer alacritty
# hyprctl dispatch workspace $((current_ws + 1)) 
# alacritty &
#



external=$(hyprctl monitors | grep '^Monitor' | awk '{print $2}' | grep '^HDMI' | head -n 1)

if [ -n "$external" ]; then
    hyprctl dispatch exec "[workspace 10 silent] firefox -P hyprland"
    # hyprctl dispatch exec "[workspace 10 silent] firefox"
    hyprctl dispatch exec "[workspace 11 silent] alacritty"
else
    hyprctl dispatch exec "[workspace 1 silent] firefox -P hyprland"
    # hyprctl dispatch exec "[workspace 1 silent] firefox"
    hyprctl dispatch exec "[workspace 2 silent] alacritty"
fi

