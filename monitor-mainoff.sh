#!/bin/bash

if grep eDP1; then
	xrandr --output eDP1 --off
else
	xrandr --output eDP-1 --off
fi

ratpoison -c restart
