#!/bin/bash

# Détection de l'environnement Wayland ou X11
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    # echo "Lancement de Firefox avec Wayland"
    MOZ_ENABLE_WAYLAND=1 firefox -P hyprland "$@"
else
    # echo "Lancement de Firefox avec X11"
    MOZ_ENABLE_WAYLAND=0 firefox -P default-release "$@"
fi

