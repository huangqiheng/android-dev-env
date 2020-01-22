#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo
	install_astrill
}

main "$@"; exit $?
