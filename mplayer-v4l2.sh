#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt mplayer
	mplayer tv:// -tv driver=v4l2:width=1920:height=1080:device=/dev/video0
}

main "$@"; exit $?



