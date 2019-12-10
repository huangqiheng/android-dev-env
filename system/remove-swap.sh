#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	check_sudo
	sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

main "$@"; exit $?
