#!/usr/bin/env bash

if [[ "$SENDER" == "theme_changed" ]]; then
	sketchybar --reload
fi
