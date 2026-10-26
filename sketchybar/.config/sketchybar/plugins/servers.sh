#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/settings.sh"

listening="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR > 1 { sub(/.*:/, "", $9); print $9 }' | sort -un)"

port_of() {
	local port
	port="$(sed -E 's#^[a-z]+://[^:/]+:?([0-9]*).*#\1#' <<<"$1")"
	if [[ -z "$port" ]]; then
		[[ "$1" == https* ]] && port=443 || port=80
	fi
	echo "$port"
}

running=()
for url in $SERVERS; do
	grep -qx "$(port_of "$url")" <<<"$listening" && running+=("$url")
done

if [[ "$1" == "click" ]]; then
	if ((${#running[@]} == 1)); then
		open -a "$DEV_BROWSER" "${running[0]}"
	else
		sketchybar --set servers popup.drawing=toggle
	fi
	exit 0
fi

if ((${#running[@]} == 0)); then
	sketchybar --set servers drawing=off popup.drawing=off
	exit 0
fi

ports=()
for url in "${running[@]}"; do
	ports+=("$(port_of "$url")")
done
sketchybar --set servers drawing=on icon.color="$FOAM" label="${ports[*]}"

# Rebuild the menu only when the set of running servers changed
state_file="${TMPDIR:-/tmp}/sketchybar_servers_state"
if [[ "${running[*]}" != "$(cat "$state_file" 2>/dev/null)" ]]; then
	echo "${running[*]}" >"$state_file"
	sketchybar --remove '/servers\.url\..*/' >/dev/null 2>&1
	for url in "${running[@]}"; do
		port="$(port_of "$url")"
		sketchybar --add item "servers.url.$port" popup.servers \
			--set "servers.url.$port" icon="󰖟" label="$url" \
			click_script="open -a '$DEV_BROWSER' '$url'; sketchybar --set servers popup.drawing=off"
	done
fi
