#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt wicd-curses
	wicd-curses
}

main "$@"; exit $?
