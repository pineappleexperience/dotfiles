#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/settings.sh"

vpn="$(scutil --nc status "$VPN_NAME" 2>/dev/null | head -1)"

state_file="${TMPDIR:-/tmp}/sketchybar_vpn_state"
if [[ "$vpn" != "$(cat "$state_file" 2>/dev/null)" ]]; then
	echo "$vpn" >"$state_file"
	sketchybar --trigger vpn_change
fi

if [[ "$vpn" == "Connected" ]]; then
	sketchybar --set "$NAME" drawing=on icon="󰖂" icon.color="$FOAM" label="VPN"
elif ! route -n get default >/dev/null 2>&1; then
	sketchybar --set "$NAME" drawing=on icon="󰖪" icon.color="$LOVE" label="Offline"
else
	sketchybar --set "$NAME" drawing=off
fi
