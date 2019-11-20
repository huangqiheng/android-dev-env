#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main() 
{
	check_update
	check_apt vim git net-tools
}

main "$@"; exit $?
