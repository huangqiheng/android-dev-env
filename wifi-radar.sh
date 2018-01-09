#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt wpasupplicant dhcpcd5
	check_apt wifi-radar
	wifi-radar
}

main "$@"; exit $?



