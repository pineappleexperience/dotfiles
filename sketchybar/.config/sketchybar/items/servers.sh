#!/usr/bin/env bash
# Local servers that are running. A click opens the server in the browser, a menu when several are running.

sketchybar --add item servers right \
	--set servers drawing=off updates=on update_freq=10 icon="󰒋" \
	popup.align=right \
	popup.background.color="$BASE" \
	popup.background.corner_radius=10 \
	popup.background.border_width=1 \
	popup.background.border_color="$OVERLAY" \
	script="$PLUGIN_DIR/servers.sh" \
	click_script="$PLUGIN_DIR/servers.sh click"
