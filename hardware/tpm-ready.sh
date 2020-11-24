#!/bin/dash

# . $(dirname $(readlink -f $0))/basic_functions.sh
. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_apt trousers tpm-tools

	log_y 'Check if models are supported' 
	ls -la /lib/modules/`uname -r`/kernel/drivers/char/tpm

	log_y 'Check if the modules enabled'
	lsmod | grep tpm

	log_y 'Check if the models have been load'
	dmesg | grep -i tpm
}

main "$@"; exit $?
