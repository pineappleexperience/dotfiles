#!/usr/bin/env bash
# Rosé Pine Moon in dark mode, Rosé Pine Dawn in light mode (https://rosepinetheme.com/palette)

if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then
	BASE=0xff232136
	OVERLAY=0xff393552
	MUTED=0xff6e6a86
	SUBTLE=0xff908caa
	TEXT=0xffe0def4
	LOVE=0xffeb6f92
	GOLD=0xfff6c177
	FOAM=0xff9ccfd8
	IRIS=0xffc4a7e7
else
	BASE=0xfffaf4ed
	OVERLAY=0xfff2e9e1
	MUTED=0xff9893a5
	SUBTLE=0xff797593
	TEXT=0xff575279
	LOVE=0xffb4637a
	GOLD=0xffea9d34
	FOAM=0xff56949f
	IRIS=0xff907aa9
fi
