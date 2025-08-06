#!/bin/bash

# Nom de l'écran interne
internal="eDP-1"

# Trouver le premier écran HDMI connecté
external=$(hyprctl monitors | grep '^Monitor' | awk '{print $2}' | grep '^HDMI' | head -n 1)

# Si un écran externe est détecté
if [ -n "$external" ]; then
    # Activer l'écran externe à gauche
    hyprctl keyword monitor "$external,preferred,0x0,1"

    # Obtenir la largeur du moniteur externe
    ext_width=$(hyprctl monitors | awk -v mon="$external" '
        $0 ~ "Monitor "mon {
            getline
            if (match($0, /[0-9]+x[0-9]+/)) {
                split(substr($0, RSTART, RLENGTH), res, "x");
                print res[1];
            }
        }
    ')

    # Définir un décalage vertical (en pixels)
    offset_y=200

    # Positionner eDP-1 à droite et décalé vers le bas
    hyprctl keyword monitor "$internal,1920x1080@60.01,${ext_width}x${offset_y},1"
else
    # Aucun écran externe, centrer eDP-1
    hyprctl keyword monitor "$internal,1920x1080@60.01,0x0,1"
fi

