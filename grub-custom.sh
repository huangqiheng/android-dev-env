#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	add-apt-repository ppa:danielrichter2007/grub-customizer
	apt-get update
	apt-get install grub-customizer
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
