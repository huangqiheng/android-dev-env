#!/bin/dash

bright="${1:-1.2}"

screen=$(xrandr | grep " connected" | awk '{print $1}')
xrandr --output $screen --brightness "$bright"
