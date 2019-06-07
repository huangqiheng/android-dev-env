#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_hotspot_card
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

	log_r "Wireless card doesn't support AP mode."
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
