#!/usr/bin/env bash
# Merge requests waiting for my review and pipelines of my open merge requests, only while the VPN is connected

sketchybar --add item gitlab right \
	--set gitlab drawing=off updates=on update_freq=300 icon="" \
	script="$PLUGIN_DIR/gitlab.sh" \
	click_script="$PLUGIN_DIR/gitlab.sh open" \
	--subscribe gitlab vpn_change system_woke
