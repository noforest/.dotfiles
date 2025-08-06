# #!/bin/bash
# exec > /dev/null 2>&1
#
# STATE_FILE="/run/user/$(id -u)/display_state"
#
# PRIMARY="HDMI-A-0"  # écran externe principal
#
# get_connected_outputs() {
#     xrandr | awk '/ connected/{print $1}'
# }
#
# get_all_outputs() {
#     xrandr | awk '/ connected|disconnected/{print $1}'
# }
#
# prev_state=""
# if [ -f "$STATE_FILE" ]; then
#     prev_state=$(cat "$STATE_FILE")
# fi
#
# mapfile -t outs < <(get_connected_outputs | sort)
# current_state=$(printf "%s|" "${outs[@]}")
#
# if [ "$current_state" != "$prev_state" ]; then
#     echo "$current_state" > "$STATE_FILE"
#
#     # Activation avec extension et positionnement
#     for o in "${outs[@]}"; do
#         if [ "$o" = "$PRIMARY" ]; then
#             # écran principal activé en mode auto
#             xrandr --output "$o" --auto --primary
#         else
#             # écrans secondaires positionnés à droite de l'écran principal, en mode auto
#             xrandr --output "$o" --auto --right-of "$PRIMARY"
#         fi
#     done
#
#     # Désactive les sorties déconnectées
#     mapfile -t all_outs < <(get_all_outputs)
#     for o in "${all_outs[@]}"; do
#         if ! printf '%s\n' "${outs[@]}" | grep -qx "$o"; then
#             xrandr --output "$o" --off
#         fi
#     done
#
#     feh --bg-fill "$WALLPAPER"
# fi
#
# # echo $current_state
# #
# # for o in "${outs[@]}"; do
# #     echo "$o"
# # done
# #
# # mapfile -t all_outs < <(get_all_outputs)
# # for o in "${all_outs[@]}"; do
# #     if ! printf '%s\n' "${outs[@]}" | grep -qx "$o"; then
# #         echo "$o"
# #     fi
# # done
#
#
