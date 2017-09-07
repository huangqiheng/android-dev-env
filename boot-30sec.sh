#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	input_time="30sec"
	if [ -n "$1" ]; then
		input_time="$1"
	fi

	ini_file=/etc/systemd/system/network-online.target.wants/networking.service
	set_conf $ini_file
	set_conf TimeoutStartSec $input_time
	if grep TimeoutStartSec $ini_file; then
		log 'done!'
	fi
}

main "$@"; exit $?

