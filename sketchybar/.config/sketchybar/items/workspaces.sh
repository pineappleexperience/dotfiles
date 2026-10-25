#!/usr/bin/env bash
# AeroSpace workspaces with the icons of their apps. A hidden item updates all of them at once.

sketchybar --add event aerospace_workspace_change

for workspace in $(aerospace list-workspaces --all); do
	sketchybar --add item "workspace.$workspace" left \
		--set "workspace.$workspace" drawing=off \
		icon="$workspace" \
		icon.font="$FONT:Bold:13.0" \
		label.font="sketchybar-app-font:Regular:14.0" \
		label.y_offset=-1 \
		background.color="$OVERLAY" \
		background.corner_radius=6 \
		background.height=24 \
		background.drawing=off \
		padding_left=4 \
		click_script="aerospace workspace $workspace"
done

sketchybar --add item workspaces left \
	--set workspaces drawing=off updates=on script="$PLUGIN_DIR/workspaces.sh" \
	--subscribe workspaces aerospace_workspace_change front_app_switched display_change system_woke
