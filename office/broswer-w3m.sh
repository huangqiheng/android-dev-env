#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	nocmd_update w3m
	check_apt w3m w3m-img

}

main "$@"; exit $?
