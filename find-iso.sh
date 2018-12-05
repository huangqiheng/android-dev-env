#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	find $1 -type f -name *.iso -size +500M
}

main "$@"; exit $?
