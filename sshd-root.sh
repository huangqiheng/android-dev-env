#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	set_conf /etc/ssh/sshd_config
	set_conf Protocol 2 " "
	set_conf LoginGraceTime 2m " "
	set_conf PermitRootLogin yes " "
	set_conf StrictModes yes " "
	set_conf TCPKeepAlive yes " "
	set_conf ClientAliveInterval 20 " "
	set_conf ClientAliveCountMax 5 " "


	systemctl restart sshd
}

main "$@"; exit $?

