#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	devdir=$(adb shell find /dev -name 'by-name' 2>/dev/null)
	log_y "ls -la $devdir"
	adb shell ls -la $devdir
}

main "$@"; exit $?
