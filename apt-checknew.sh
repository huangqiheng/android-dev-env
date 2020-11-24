#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	empty_exit "$1" 'Package Name'
	check_update
	apt-get --only-upgrade install "$1"
}

main "$@"; exit $?
