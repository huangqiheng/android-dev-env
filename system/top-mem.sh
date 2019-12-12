#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	top -o %MEM
}

main "$@"; exit $?
