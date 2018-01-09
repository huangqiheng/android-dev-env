#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt mplayer
	mplayer tv:// -tv driver=v4l2:device=$1
}

main "$@"; exit $?



