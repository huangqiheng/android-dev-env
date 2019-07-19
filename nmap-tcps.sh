#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt nmap arp-scan

	cd /usr/share/nmap
	if [ ! -f nmap-os-db ]; then
		wget https://svn.nmap.org/nmap/nmap-os-db
	fi

	empty_exit "$1" 'target ip address'
	nmap_scan_tcps "$1"
}

nmap_scan_tcps()
{
	local target="$1"
	nmap -n -PN -sT -p- "$target"
	#nmap -n -PN -sT -sU -p- "$target"
}

fast_nmap_scan_exit()
{
	nmap -p 22 --open -sV 192.168.1.0/24
}

maintain()
{
	[ "$1" = 'fast' ] && fast_nmap_scan_exit $2
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
