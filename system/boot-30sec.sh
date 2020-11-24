#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	input_time="30"
	if [ -n "$1" ]; then
		input_time="$1"
	fi

	boot_time="${input_time}sec"
	ini_file=/etc/systemd/system/network-online.target.wants/networking.service
	set_conf $ini_file
	set_conf TimeoutStartSec $boot_time
	if grep TimeoutStartSec $ini_file; then
		log 'networking.service done!'
	fi

	boot_time="${input_time};"
	ini_file=/etc/dhcp/dhclient.conf
	set_conf $ini_file
	set_conf timeout $boot_time " "
	if grep "timeout $boot_time" $ini_file; then
		log 'dhclient.conf done!'
	fi
}

main "$@"; exit $?

