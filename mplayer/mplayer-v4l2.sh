#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	devPath="$1"
	if [ -z $1 ]; then
		devPath="/dev/video0"
	fi

	check_apt mplayer
	mplayer tv:// -tv driver=v4l2:width=1920:height=1080:device=${devPath}
}

main "$@"; exit $?



