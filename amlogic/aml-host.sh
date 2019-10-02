#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt nmap

	if [ -z "$1" ]; then
		for subnet in $(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'); do
			nmap -sP $subnet | grep "Nmap scan report for aml" 
		done
	else 
		nmap -sP "$1" | grep "Nmap scan report for aml" 
	fi
	
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
