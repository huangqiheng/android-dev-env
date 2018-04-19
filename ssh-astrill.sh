#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main ()  
{
	# ssh USER@FINAL_DEST -o "ProxyCommand=nc -X connect -x 127.0.0.1:3213 %h %p"
	ssh "$1" -o "ProxyCommand=nc -X connect -x 127.0.0.1:3213 %h %p"
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat <<< EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?

