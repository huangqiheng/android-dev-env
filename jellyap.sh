#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

AP_IFACE="${AP_IFACE:-wlan0}"
WAN_IFACE="${WAN_IFACE:-eth0}"
SSID="${SSID:-DangerousHotspot}"
PASSWORD="${PASSWORD:-DontConnectMe}"

main () 
{
	cd $RUN_DIR
	if [ ! -d jellyap ]; then 
		git clone https://github.com/7sDream/jellyap.git
		cd jellyap
		chmod +x jellyap.sh
	fi

	if ! cmd_exists jellyap; then
		make_cmdline jellyap <<-EOF
		#!/bin/dash
		cd $RUN_DIR/jellyap
		./jellyap.sh $AP_IFACE $WAN_IFACE $SSID $PASSWORD no
EOF
	fi

	jellyap
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
