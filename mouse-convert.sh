#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	mxid=$(xinput --list --short | awk '/Trackball/{gsub(/.*id=/, "");gsub(/[[:blank:]].*/, "");print}')
	bmap=$(xinput get-button-map $mxid)
	nmap=$(awk '{s=$1;$1=$3;$3=s};1' <<<$bmap)
	xinput set-button-map $mxid $nmap
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat <<< EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
