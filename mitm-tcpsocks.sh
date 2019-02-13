#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

AP_IFACE="${AP_IFACE:-wlan0}"
SOCKS_HOST="${HOST:-127.0.0.1}"
SOCKS_PORT="${PORT:-3128}"

main () 
{
	log_y 'starting tcpsocks'

	nocmd_update tcpsocks
	check_apt iptables 

	cd $RUN_DIR
	if [ ! -d tcpsocks ]; then
		git clone https://github.com/vi/tcpsocks.git
	fi

	if ! cmd_exists tcpsocks; then
		cd tcpsocks
		make
		cp tcpsocks /usr/local/bin/
	fi

	iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp  -j REDIRECT --to-ports 1234 > /dev/null 2>&1 || true
	iptables -t nat -A PREROUTING -i $AP_IFACE -p tcp  -j REDIRECT --to-ports 1234

	tcpsocks 0.0.0.0 1234 REDIRECT REDIRECT "$SOCKS_HOST" "$SOCKS_PORT" &
	PIDS2KILL="$PIDS2KILL $!"

	waitfor_die "$(cat <<-EOL
	iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp  -j REDIRECT --to-ports 1234 > /dev/null 2>&1 || true
	kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
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
