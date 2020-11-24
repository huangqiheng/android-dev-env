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

	for ip in $(ipaddr_list); do
		log ""
		log "------------------- detecting $ip -------------------------"
		nmap -O -Pn $ip
	done
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
