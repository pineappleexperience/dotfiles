#!/usr/bin/env bash
# Bluetooth devices have their address as uid, wired headphones use the built-in headphone output.

source "$CONFIG_DIR/colors.sh"

device="$(SwitchAudioSource -c -t output -f json 2>/dev/null)"
uid="$(jq -r '.uid // empty' <<<"$device")"
name="$(jq -r '.name // empty' <<<"$device")"

if [[ -z "$uid" || "$uid" == BuiltInSpeaker* ]]; then
	sketchybar --set "$NAME" drawing=off
	exit 0
fi

if [[ "$uid" =~ ^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2} || "$uid" == BuiltInHeadphone* ]]; then
	icon="󰋋"
else
	icon="󰓃"
fi
[[ ${#name} -gt 20 ]] && name="${name:0:19}…"

sketchybar --set "$NAME" drawing=on icon="$icon" icon.color="$IRIS" label="$name"
