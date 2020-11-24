#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	nocmd_update lynx
	check_apt lynx

}

main "$@"; exit $?
