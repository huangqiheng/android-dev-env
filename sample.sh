#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat <<< EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
