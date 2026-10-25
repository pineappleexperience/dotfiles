#!/usr/bin/env bash
# Local servers: the configured ports that something listens on

sketchybar --add item servers right \
	--set servers drawing=off updates=on update_freq=10 icon="󰒋" \
	script="$PLUGIN_DIR/servers.sh"
