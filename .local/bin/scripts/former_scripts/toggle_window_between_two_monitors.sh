#!/bin/bash

# Récupérer l'index du moniteur de la fenêtre active
monitor_index=$(hyprctl activewindow -j | jq -r '.monitor')

# Trouver le nom du moniteur correspondant à l'index
monitor_name=$(hyprctl monitors -j | jq -r --argjson idx "$monitor_index" '.[] | select(.id == $idx) | .name')

# Toggle entre les moniteurs
if [ "$monitor_name" = "HDMI-A-1" ]; then
    hyprctl dispatch movewindow mon:eDP-1
else
    hyprctl dispatch movewindow mon:HDMI-A-1
fi
