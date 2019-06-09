#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	ifaces=$(get_wifi_ifaces)
	echo $ifaces
	check_hotspot_card $ifaces
}

check_hotspot_card()
{
	local support_list=
	local unsupport_list=
	for interface in "$@"; do
		local PHY=$(cat /sys/class/net/${interface}/phy80211/name)
		if iw phy "$PHY" info | grep -qE "^\s+\* AP$"; then
			support_list="${support_list} ${interface}"
		else
			unsupport_list="${unsupport_list} ${interface}"
		fi
	done

	log_y "AP mode iface: $support_list"
	log_y "Not support: $unsupport_list"
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
