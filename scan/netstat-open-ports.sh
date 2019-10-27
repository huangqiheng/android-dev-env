#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	netstat -plunt
}

ssh_port_exit()
{
	netstat -plunt | grep ssh
	exit
}

remote_ports_exit()
{
	nmap -n -PN -sT -sU -p- "$1"
	exit
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'ssh' ] && ssh_port_exit
	[ "$1" = 'remote' ] && remote_ports_exit "$2"
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
