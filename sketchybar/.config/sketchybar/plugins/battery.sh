#!/usr/bin/env bash
# Battery level, red below 20 %. Hidden on Macs without a battery.

source "$CONFIG_DIR/colors.sh"

info="$(pmset -g batt)"
percentage="$(grep -Eo '[0-9]+%' <<<"$info" | head -1 | tr -d '%')"
if [[ -z "$percentage" ]]; then
	sketchybar --set "$NAME" drawing=off
	exit 0
fi

if grep -q 'AC Power' <<<"$info"; then
	icon="󰂄"
elif ((percentage >= 90)); then
	icon="󰁹"
elif ((percentage >= 70)); then
	icon="󰂀"
elif ((percentage >= 50)); then
	icon="󰁾"
elif ((percentage >= 30)); then
	icon="󰁼"
else
	icon="󰁺"
fi
color=$( ((percentage < 20)) && echo "$LOVE" || echo "$TEXT")

sketchybar --set "$NAME" drawing=on icon="$icon" icon.color="$color" label="$percentage%"
