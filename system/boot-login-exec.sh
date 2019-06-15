#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo
	set_cmdline loginexec
	set_cmdline "$@" 

	auto_login root
	handle_rc '/root/.bashrc' loginexec "if [ \"\$(tty)\" = \"/dev/tty1\" ]; then loginexec; fi"
}

main "$@"; exit $?



