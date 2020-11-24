#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_sudo
	apt update -y
	apt upgrade -y
	apt dist-upgrade -y

	set_conf /etc/update-manager/release-upgrades
	set_conf Prompt normal

	do-release-upgrade -y
}

main "$@"; exit $?
