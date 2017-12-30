#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	set_conf /etc/ssh/sshd_config
	set_conf LoginGraceTime 120 " "
	set_conf PermitRootLogin yes " "
	set_conf StrictModes yes " "

	systemctl restart sshd
}

main "$@"; exit $?

