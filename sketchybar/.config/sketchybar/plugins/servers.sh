#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/settings.sh"

listening="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR > 1 { sub(/.*:/, "", $9); print $9 }' | sort -un)"

active=""
for port in $SERVER_PORTS; do
	grep -qx "$port" <<<"$listening" && active+="$port "
done

if [[ -n "$active" ]]; then
	sketchybar --set "$NAME" drawing=on icon.color="$FOAM" label="${active% }"
else
	sketchybar --set "$NAME" drawing=off
fi
