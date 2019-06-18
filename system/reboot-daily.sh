#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo
	set_cmdline dailyexec
	set_cmdline "$@" 

	handle_rc '/etc/crontab' dailyexec "44 4 * * * /usr/local/bin/dailyexec"
}

main "$@"; exit $?



