#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	for iface in $(get_wifi_ifaces); do
		if is_apmode "$iface"; then
			log_y "$iface can be AP"
		else
			log_y "$iface can't be AP"
		fi
	done
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
