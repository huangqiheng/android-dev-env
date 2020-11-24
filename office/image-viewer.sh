#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	if cmd_exists "feh"; then
		feh "$1"
		exit 0
	fi

	if cmd_exists "display"; then
		display "$1"
		exit 0
	fi

	if [ "$1" = "feh" ]; then
		check_update_once
		check_apt feh
		feh "$2"
		exit 0
	fi

	if [ "$1" = "display" ]; then
		check_update_once
		check_apt imagemagick
		display "$2"
		exit 0
	fi

	check_update_once
	check_apt feh
	feh "$1"
}



maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL
	feh /path/to/image
	display /path/to/image
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
