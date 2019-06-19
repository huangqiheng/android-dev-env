#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	local devName=$1
	if [ "X$devName" = 'X' ]; then
		devName=$(iface_list)
	fi

	for iface in $devName; do
		# cat /sys/class/net/$iface/speed
		speed=$(mii-tool $iface)
		log_y "$speed"
	done

}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
