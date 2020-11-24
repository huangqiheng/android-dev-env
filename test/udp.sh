#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	if [ "$1" = 'server' ]; then
		nc -ul 1080
		exit
	fi

	nc -u 127.0.0.1 1080
}

main "$@"; exit $?
