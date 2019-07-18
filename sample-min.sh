#!/bin/dash

# . $(dirname $(readlink -f $0))/basic_functions.sh
. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo
}

main "$@"; exit $?
