#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{

	for subnet in $(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'); do
		nmap -sP $subnet | grep "Nmap scan report for aml" 
	done
	
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
