#!/usr/bin/env bash
# delta in the Rosé Pine variant that matches the macOS appearance (like the terminal).

if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then
	exec delta --dark --syntax-theme=rose-pine-moon "$@"
else
	exec delta --light --syntax-theme=rose-pine-dawn "$@"
fi
