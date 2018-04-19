#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	local devname="$1"
	local ssid="$2"

	ip link set $devname up

	if [ -z $devname ]; then
		log 'please input dev name'
		exit 1
	fi

	if [ -z $ssid ]; then
		log 'please input ssid'
		exit 1
	fi

	iw $devname connect "$ssid"
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'dev' ] && show_devs_exit 
	[ "$1" = 'link' ] && show_link_exit $2
	[ "$1" = 'scan' ] && show_scan_exit $2
	[ "$1" = 'up' ] && linkup_exit $2
	[ "$1" = 'down' ] && linkdown_exit $2
}

linkup_exit()
{
	ip link set "$1" up
	exit 0
}

linkdown_exit()
{
	ip link set "$1" down
	exit 0
}

show_scan_exit()
{
	iw "$1" scan -u
	exit 0
}

show_link_exit()
{
	iw "$1" link 
	exit 0
}

show_devs_exit()
{
	iw dev | grep -i Interface
	exit 0
}

show_help_exit()
{
	cat << EOL
	sudo sh wifi-iw-open.sh "devName" "yourSsid"

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
