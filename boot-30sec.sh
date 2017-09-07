#!/bin/bash

. ./basic_functions.sh

main () 
{
	check_sudo

	ini_file=/etc/systemd/system/network-online.target.wants/networking.service
	set_conf $ini_file
	set_conf TimeoutStartSec 30sec
	grep TimeoutStartSec $ini_file
}





main "$@"; exit $?

