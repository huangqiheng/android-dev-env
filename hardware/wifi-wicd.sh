#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt wicd-curses
	systemctl enable wicd
	systemctl start wicd
	log 'Please run wicd-curses'
}

main "$@"; exit $?
