#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	pids=$(ps aux | awk '$8=="Z" {print $2}')


	if [ "X$pids" = 'X' ]; then
		echo "no zombie processes"
		exit 0
	else
		echo "zombie processes is: $pids"
	fi

	parents=$(ps o ppid= $pids)
	echo "zombie parents is: $parents"

	if [ "$1" = 'kill' ]; then
		kill $parents
		exit 0
	fi

	echo "kill it with: ./zombie.sh kill"
}

main "$@"; exit $?
