#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt ethtool

	local devName=$1
	if [ "X$devName" = 'X' ]; then
		devName=$(iface_list)
	fi

	for iface in $devName; do
		# cat /sys/class/net/$iface/speed
		speed=$(ethtool $iface | grep Speed)
		log_y "$iface: $speed"
	done
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
