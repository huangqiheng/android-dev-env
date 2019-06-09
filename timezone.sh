#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt ntp
	timedatectl set-ntp on

	check_apt tzdata
	dpkg-reconfigure tzdata
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
