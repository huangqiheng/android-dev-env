#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	if cmd_exists "gimp"; then
		gimp "$1"
		exit 0
	fi


	if [ "$1" = "gimp" ]; then
		check_update_once ppa:otto-kesselgulasch/gimp
		check_apt gimp
		gimp "$2"
		exit 0
	fi

	check_update_once ppa:otto-kesselgulasch/gimp
	check_apt gimp

	if [ ! -z "$1" ]; then
		gimp "$1"
	fi
}



maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL
	gimp /path/to/image
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
