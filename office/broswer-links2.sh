#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	nocmd_update links2
	check_apt links2

}

main "$@"; exit $?
