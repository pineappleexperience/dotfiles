#!/usr/bin/env bash
# VPN while connected, a warning while offline, nothing otherwise. Triggers vpn_change for the GitLab item.

sketchybar --add event vpn_change \
	--add item network right \
	--set network drawing=off updates=on update_freq=10 \
	script="$PLUGIN_DIR/network.sh" \
	--subscribe network wifi_change system_woke
