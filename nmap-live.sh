#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt nmap arp-scan

	cd /usr/share/nmap
	if [ ! -f nmap-os-db ]; then
		wget https://svn.nmap.org/nmap/nmap-os-db
	fi

	for ip in $(get_local_ips); do
		log ""
		log "------------------- detecting $ip -------------------------"
		nmap -O -Pn $ip
	done
}

get_local_ips()
{
	arp-scan --interface=enp2s0 --localnet 2>/dev/null | awk '{print $1}' | tail -n +3 | head -n -2
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
