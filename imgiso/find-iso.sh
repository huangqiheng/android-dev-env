#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo
	find / -type f -name *.iso -size +500M -a -size -10G
}

main "$@"; exit $?
