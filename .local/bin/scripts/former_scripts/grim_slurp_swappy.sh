#!/bin/bash
filename=~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png
grim -g "$(slurp)" "$filename" && swappy -f "$filename"

