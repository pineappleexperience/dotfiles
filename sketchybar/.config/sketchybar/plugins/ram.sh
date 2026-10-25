#!/usr/bin/env bash
# Used memory as macOS counts it for memory pressure, yellow from 80 %, red from 90 %

source "$CONFIG_DIR/colors.sh"

free="$(memory_pressure | awk '/free percentage/ { print $5 }' | tr -d '%')"
used=$((100 - ${free:-100}))

if ((used >= 90)); then
	color="$LOVE"
elif ((used >= 80)); then
	color="$GOLD"
else
	color="$TEXT"
fi

sketchybar --set "$NAME" label="$used%" icon.color="$color" label.color="$color"
