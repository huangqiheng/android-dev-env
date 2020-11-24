#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main() 
{
	daily_exec '/sbin/shutdown -r +4'
}

main "$@"; exit $?



