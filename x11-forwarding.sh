#!/bin/sh

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	num_param=$#
	if [ $num_param -eq 0 ]; then
		x11_forward_server
		exit 0
	fi

	if [ "$1" = 'client' ]; then
		x11_forward_client
		return 0
	fi

	ssh_target=$1
	ssh_opt="$2"
	IFS='@'; set -- "$1"
	hostName=$2

	if ping -c 1 "$hostName" &> /dev/null; then
		x11_forward_client
		ssh -v -X "$ssh_target" "$ssh_opt"
		exit 0
	fi

	exit 1
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
