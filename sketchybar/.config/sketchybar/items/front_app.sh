#!/usr/bin/env bash
# Icon and name of the focused app

sketchybar --add item front_app left \
	--set front_app display=active \
	padding_left=12 \
	icon.font="sketchybar-app-font:Regular:15.0" \
	label.font="$FONT:Bold:13.0" \
	script="$PLUGIN_DIR/front_app.sh" \
	--subscribe front_app front_app_switched
