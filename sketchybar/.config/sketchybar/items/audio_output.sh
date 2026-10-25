#!/usr/bin/env bash
# Headphones or another external audio output, hidden while the built-in speakers play

sketchybar --add item audio_output right \
	--set audio_output drawing=off updates=on update_freq=5 \
	script="$PLUGIN_DIR/audio_output.sh" \
	--subscribe audio_output volume_change system_woke
