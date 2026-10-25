#!/usr/bin/env bash
# Shows the workspaces that have windows or are focused, with the icons of their apps, on the display of
# their monitor.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
windows="$(aerospace list-windows --all --format '%{workspace}|%{app-name}')"

args=()
while IFS='|' read -r workspace display; do
	icons=""
	while IFS= read -r app; do
		[[ -z "$app" ]] && continue
		__icon_map "$app"
		icons+="$icon_result "
	done < <(awk -F'|' -v w="$workspace" '$1 == w { print $2 }' <<<"$windows" | sort -u)
	icons="${icons% }"
	label_drawing=$([[ -n "$icons" ]] && echo on || echo off)

	if [[ "$workspace" == "$focused" ]]; then
		args+=(--set "workspace.$workspace" drawing=on display="$display" label="$icons" label.drawing="$label_drawing"
			icon.color="$IRIS" label.color="$TEXT" background.drawing=on)
	elif [[ -n "$icons" ]]; then
		args+=(--set "workspace.$workspace" drawing=on display="$display" label="$icons" label.drawing=on
			icon.color="$SUBTLE" label.color="$SUBTLE" background.drawing=off)
	else
		args+=(--set "workspace.$workspace" drawing=off)
	fi
done < <(aerospace list-workspaces --all --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}')

sketchybar "${args[@]}"
