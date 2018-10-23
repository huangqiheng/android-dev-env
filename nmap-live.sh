#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt nmap

	cd /usr/share/nmap
	if [ ! -f nmap-os-db ]; then
		wget https://svn.nmap.org/nmap/nmap-os-db
	fi

	nmap -sP -PS22,3389 192.168.2.1/24
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
