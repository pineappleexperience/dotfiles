#!/usr/bin/env bash

sketchybar --add item clock right \
	--set clock update_freq=30 \
	icon.drawing=off \
	padding_right=8 \
	label.font="$FONT:Bold:13.0" \
	script="$PLUGIN_DIR/clock.sh" \
	--subscribe clock system_woke
