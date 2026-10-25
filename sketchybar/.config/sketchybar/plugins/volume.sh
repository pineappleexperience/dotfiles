#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

if [[ "$SENDER" == "volume_change" ]]; then
	volume="$INFO"
else
	volume="$(osascript -e 'output volume of (get volume settings)')"
fi
muted="$(osascript -e 'output muted of (get volume settings)')"

if [[ "$muted" == "true" || "$volume" == "0" ]]; then
	icon="󰖁"
elif ((volume < 34)); then
	icon="󰕿"
elif ((volume < 67)); then
	icon="󰖀"
else
	icon="󰕾"
fi

sketchybar --set "$NAME" icon="$icon" label="$volume%" \
	icon.color="$([[ "$muted" == "true" ]] && echo "$MUTED" || echo "$TEXT")"
