#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt exfat-utils exfat-fuse
	mount -t exfat $1 $2
}

main "$@"; exit $?

