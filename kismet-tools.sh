#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt ubertooth 
	check_apt wireshark
	check_apt kismet kismet-plugins
	check_apt aircrack-ng

	logprefix=/var/log/kismet
	mkdir -p $logprefix
	chownUser $logprefix
	set_conf /etc/kismet/kismet.conf
	set_conf logprefix $logprefix

	WIRELESS_IFACE=$(get_wifi_ifaces)
	set_conf ncsource $WIRELESS_IFACE
	set_conf listen 'tcp://0.0.0.0:2501'
	set_conf allowedhosts '0.0.0.0'
	set_conf gps 'false'

	set_conf /etc/kismet/kismet_drone.conf
	set_conf ncsource $WIRELESS_IFACE
	set_conf dronelisten 'tcp://0.0.0.0:2502'
	set_conf droneallowedhosts '0.0.0.0'
	set_conf gps 'false'
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
